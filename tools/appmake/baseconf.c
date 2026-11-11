/*
 * BaseConf TAP backend for z88dk appmake.
 * Copyright (c) 2026 BaseConf contributors.
 *
 * Adds ZX Evolution BaseConf TAP loading and physical-page selection to the
 * upstream z88dk appmake driver. RAM/turbo mode comes from ERS/BAS48 startup.
 * See tools/appmake/README.en.md for provenance.
 */

#include "appmake.h"
#include <errno.h>
#include <limits.h>

#define BASIC_MAX 32768
#define BASECONF_WINDOW_START 0xc000
#define BASECONF_WINDOW_END 0x10000
#define BASECONF_PORT_CONFIG 0x00bf
#define BASECONF_PORT_W3 0xfff7
#define BASECONF_PORT_RAM_PAGE 0xf7f7

static struct {
    char *binname;
    char *crtfile;
    char *outfile;
    char *name;
    char *bank_prefix;
    int org;
    int usr_address;
    int clear_address;
} bc = {NULL, NULL, NULL, NULL, NULL, -1, -1, -1};

option_t baseconf_options[] = {
    {'b', "binfile", "Linked binary file", OPT_STR, &bc.binname},
    {'c', "crt0file", "crt0 file used in linking", OPT_STR, &bc.crtfile},
    {'o', "output", "Name of output TAP file", OPT_STR, &bc.outfile},
    {0, "name", "TAP program name (1-10 characters; default BASECONF)", OPT_STR, &bc.name},
    {0, "bank-prefix", "Prefix for bank TAP names (1-7 characters; default BANK)", OPT_STR,
     &bc.bank_prefix},
    {0, "org", "Override the address of the main load image", OPT_INT, &bc.org},
    {0, "usraddr", "Address to run after loading (defaults to map symbol start)", OPT_INT,
     &bc.usr_address},
    {0, "clearaddr", "Address to CLEAR at (defaults to 0x5fff)", OPT_INT, &bc.clear_address},
    {0, NULL, NULL, OPT_NONE, NULL}};

struct image_range {
    unsigned start;
    unsigned end;
    unsigned char *data;
};

static int map_symbol_address(FILE *map, const char *wanted, unsigned *address) {
    char line[1024];
    char symbol[128];
    unsigned value;

    rewind(map);
    while (fgets(line, sizeof(line), map)) {
        if (sscanf(line, "%127s = $%x", symbol, &value) == 2 && strcmp(symbol, wanted) == 0) {
            *address = value;
            return 0;
        }
    }
    return -1;
}

static int append_text(char *buffer, size_t capacity, size_t *used, const char *text) {
    size_t len = strlen(text);
    if (*used + len > capacity) return -1;
    memcpy(buffer + *used, text, len);
    *used += len;
    return 0;
}

static int append_integer(char *buffer, size_t capacity, size_t *used, int value) {
    char number[16];
    snprintf(number, sizeof(number), "%d", value);
    if (*used + strlen(number) + 3 > capacity) return -1;
    buffer[(*used)++] = (char)0xb0; /* VAL "decimal" */
    buffer[(*used)++] = '"';
    if (append_text(buffer, capacity, used, number)) return -1;
    buffer[(*used)++] = '"';
    return 0;
}

static int append_separator(char *buffer, size_t capacity, size_t *used) {
    return *used ? append_text(buffer, capacity, used, ":") : 0;
}

static int append_basic_out_port(char *buffer, size_t capacity, size_t *used, unsigned port) {
    if (append_separator(buffer, capacity, used)) return -1;
    if (*used + 1 >= capacity) return -1;
    buffer[(*used)++] = (char)0xdf; /* OUT */
    if (append_text(buffer, capacity, used, " ")) return -1;
    if (append_integer(buffer, capacity, used, (int)port)) return -1;
    return append_text(buffer, capacity, used, ",");
}

static int append_basic_out_statement(char *buffer, size_t capacity, size_t *used, unsigned port,
                                      unsigned value) {
    if (append_basic_out_port(buffer, capacity, used, port)) return -1;
    return append_integer(buffer, capacity, used, (int)value);
}

static int append_open_baseconf_page_registers(char *buffer, size_t capacity, size_t *used) {
    /* LET b=IN 191 : OUT 191,2*INT (b/2)+1. Preserve the ROM's tape
     * breakpoint and any other BF flags while enabling shadow ports. */
    if (append_text(buffer, capacity, used,
                    "\xf1"
                    "b=\xbf") ||
        append_integer(buffer, capacity, used, BASECONF_PORT_CONFIG) ||
        append_basic_out_port(buffer, capacity, used, BASECONF_PORT_CONFIG) ||
        append_integer(buffer, capacity, used, 2) ||
        append_text(buffer, capacity, used, "*\xba(b/") ||
        append_integer(buffer, capacity, used, 2) || append_text(buffer, capacity, used, ")+"))
        return -1;
    return append_integer(buffer, capacity, used, 1);
}

static int append_select_bank_w3_page(char *buffer, size_t capacity, size_t *used,
                                      unsigned char page) {
    /* Disable 7FFD substitution before selecting the full page. */
    if (append_basic_out_statement(buffer, capacity, used, BASECONF_PORT_W3,
                                   0x40 | ((unsigned char)~page & 0x3f)))
        return -1;
    return append_basic_out_statement(buffer, capacity, used, BASECONF_PORT_RAM_PAGE,
                                      (unsigned char)~page);
}

static int append_close_baseconf_page_registers(char *buffer, size_t capacity, size_t *used) {
    if (append_basic_out_port(buffer, capacity, used, BASECONF_PORT_CONFIG)) return -1;
    return append_text(buffer, capacity, used, "b");
}

static int append_load(char *buffer, size_t capacity, size_t *used) {
    static const unsigned char load_code[] = {0xef, '"', '"', 0xaf};
    if (append_separator(buffer, capacity, used)) return -1;
    if (*used + sizeof(load_code) > capacity) return -1;
    memcpy(buffer + *used, load_code, sizeof(load_code));
    *used += sizeof(load_code);
    return 0;
}

static int append_line(char *program, size_t capacity, size_t *used, unsigned line_number,
                       const char *line, size_t length) {
    size_t line_length = length + 1; /* trailing ENTER */
    if (line_length > 255 || *used + line_length + 4 > capacity) return -1;
    program[(*used)++] = (char)(line_number >> 8);
    program[(*used)++] = (char)line_number;
    program[(*used)++] = (char)line_length;
    program[(*used)++] = (char)(line_length >> 8);
    memcpy(program + *used, line, length);
    *used += length;
    program[(*used)++] = 0x0d;
    return 0;
}

static int make_basic(char *buffer, size_t capacity, size_t *used, unsigned entry,
                      int clear_address, const struct image_range banks[MAXBANKS]) {
    char line[256];
    size_t line_used;
    int i;
    unsigned char page;
    *used = 0;

    /* BaseConf's ERS/BAS48 startup prepares RAM mode and turbo state. */
    line_used = 0;
    if (line_used + 1 > sizeof(line)) return -1;
    line[line_used++] = (char)0xfd; /* CLEAR */
    if (append_text(line, sizeof(line), &line_used, " ")) return -1;
    if (append_integer(line, sizeof(line), &line_used, clear_address)) return -1;
    if (append_line(buffer, capacity, used, 10, line, line_used)) return -1;

    line_used = 0;
    if (append_load(line, sizeof(line), &line_used) ||
        append_line(buffer, capacity, used, 20, line, line_used))
        return -1;
    for (i = 0; i < MAXBANKS; ++i) {
        if (!banks[i].data) continue;
        page = (unsigned char)i;
        line_used = 0;
        if (append_open_baseconf_page_registers(line, sizeof(line), &line_used)) return -1;
        if (append_select_bank_w3_page(line, sizeof(line), &line_used, page)) return -1;
        if (append_close_baseconf_page_registers(line, sizeof(line), &line_used)) return -1;
        if (append_load(line, sizeof(line), &line_used)) return -1;
        if (append_line(buffer, capacity, used, 30 + (unsigned)i * 10, line, line_used)) return -1;
    }
    line_used = 0;
    if (line_used + 3 > sizeof(line)) return -1;
    line[line_used++] = (char)0xf9; /* RANDOMIZE */
    line[line_used++] = (char)0xc0; /* USR */
    if (append_integer(line, sizeof(line), &line_used, (int)entry)) return -1;
    if (append_line(buffer, capacity, used, 30 + MAXBANKS * 10, line, line_used)) return -1;
    return 0;
}

static int write_tap_block(FILE *out, unsigned char flag, const unsigned char *payload,
                           size_t length) {
    unsigned char parity = 0;
    size_t i;
    if (length > 65533) return -1;
    writeword_p((unsigned)(length + 2), out, &parity);
    parity = 0;
    writebyte_p(flag, out, &parity);
    for (i = 0; i < length; ++i) writebyte_p(payload[i], out, &parity);
    writebyte_p(parity, out, &parity);
    return ferror(out) ? -1 : 0;
}

static int write_tap_header(FILE *out, unsigned type, const char *name, unsigned length,
                            unsigned p1, unsigned p2) {
    unsigned char header[17] = {0};
    size_t i;
    size_t name_length = strlen(name);
    header[0] = (unsigned char)type;
    if (name_length > 10) name_length = 10;
    for (i = 0; i < 10; ++i) header[1 + i] = (unsigned char)(i < name_length ? name[i] : ' ');
    header[11] = length & 0xff;
    header[12] = length >> 8;
    header[13] = p1 & 0xff;
    header[14] = p1 >> 8;
    header[15] = p2 & 0xff;
    header[16] = p2 >> 8;
    return write_tap_block(out, 0, header, sizeof(header));
}

static int write_basic(FILE *out, const char *name, const unsigned char *basic, size_t length) {
    if (write_tap_header(out, 0, name, (unsigned)length, 10, (unsigned)length)) return -1;
    return write_tap_block(out, 0xff, basic, length);
}

static int write_image(FILE *out, const char *name, const struct image_range *image) {
    size_t length = image->end - image->start;
    int result;
    if (length > 65533) return -1;
    result = write_tap_header(out, 3, name, (unsigned)length, image->start, 0x8000);
    if (!result) result = write_tap_block(out, 0xff, image->data, length);
    return result;
}

/* z80asm's BANK_XX binaries encode the hexadecimal page in the high
 * address byte. The generic appmake enumerator uses decimal bank names. */
static void normalize_linker_banks(struct banked_memory *memory) {
    struct memory_bank *banks = memory->bankspace[0].membank;
    int i, j;
    for (i = -1; i < MAXBANKS; ++i) {
        struct memory_bank *source = i < 0 ? &memory->mainbank : &banks[i];
        for (j = 0; j < source->num;) {
            struct section_bin section = source->secbin[j];
            unsigned page = (unsigned)section.org >> 16;
            char expected[12];
            snprintf(expected, sizeof(expected), "BANK_%02X", page);
            if (!page || page >= MAXBANKS || strcmp(section.section_name, expected)) {
                ++j;
                continue;
            }
            section.org &= 0xffff;
            if (i == (int)page) {
                source->secbin[j++] = section;
            } else {
                struct memory_bank *destination = &banks[page];
                destination->secbin = must_realloc(
                    destination->secbin, (destination->num + 1) * sizeof(*destination->secbin));
                destination->secbin[destination->num++] = section;
                --source->num;
                memmove(source->secbin + j, source->secbin + j + 1,
                        (source->num - j) * sizeof(*source->secbin));
            }
        }
    }
}

static int collect_range(struct memory_bank *bank, int include_main, struct image_range *range) {
    unsigned start = 0x10000, end = 0;
    int i, selected = 0;
    for (i = 0; i < bank->num; ++i) {
        struct section_bin *section = &bank->secbin[i];
        unsigned section_start = (unsigned)section->org;
        unsigned section_end = section_start + (unsigned)section->size;
        if (strcmp(section->section_name, "BSS") == 0 ||
            strstr(section->section_name, "_BSS") != NULL)
            continue;
        if (!section->size) continue;
        if (section->org < 0 || section_end > 0x10000 || section_end <= section_start) return -1;
        if (!include_main &&
            (section_start < BASECONF_WINDOW_START || section_end > BASECONF_WINDOW_END)) {
            fprintf(stderr, "BaseConf: bank section %s must fit in window C000-FFFF\n",
                    section->section_name);
            return -1;
        }
        if (section_start < start) start = section_start;
        if (section_end > end) end = section_end;
        selected++;
    }
    if (!selected || end <= start) return 0;
    range->start = start;
    range->end = end;
    range->data = calloc(end - start, 1);
    if (!range->data) return -1;
    for (i = 0; i < bank->num; ++i) {
        struct section_bin *section = &bank->secbin[i];
        FILE *input;
        unsigned char *dest;
        unsigned j;
        if (strcmp(section->section_name, "BSS") == 0 ||
            strstr(section->section_name, "_BSS") != NULL)
            continue;
        if (!section->size) continue;
        dest = range->data + (unsigned)section->org - start;
        input = fopen(section->filename, "rb");
        if (!input) {
            fprintf(stderr, "BaseConf: cannot open section binary %s: %s\n", section->filename,
                    strerror(errno));
            free(range->data);
            range->data = NULL;
            return -1;
        }
        if (fseek(input, (long)section->offset, SEEK_SET) != 0) {
            fclose(input);
            free(range->data);
            return -1;
        }
        for (j = 0; j < (unsigned)section->size; ++j) {
            int c = fgetc(input);
            if (c == EOF) {
                fclose(input);
                free(range->data);
                range->data = NULL;
                return -1;
            }
            dest[j] = (unsigned char)c;
        }
        fclose(input);
    }
    return 1;
}

static void free_memory_images(struct banked_memory *memory, struct image_range *main_image,
                               struct image_range banks[MAXBANKS]) {
    int i;
    free(main_image->data);
    for (i = 0; i < MAXBANKS; ++i) free(banks[i].data);
    mb_cleanup_memory(memory);
}

int baseconf_exec(char *target) {
    struct banked_memory memory;
    struct aligned_data aligned;
    struct image_range main_image = {0, 0, NULL}, banks[MAXBANKS] = {{0, 0, NULL}};
    char crtname[FILENAME_MAX + 1], mapname[FILENAME_MAX + 1], outname[FILENAME_MAX + 1];
    const char *tap_name;
    const char *bank_prefix;
    char basic[BASIC_MAX];
    size_t basic_length;
    FILE *fmap, *out;
    unsigned entry, load_org, code_entry = 0;
    int clear_address, i, result = -1, origin_delta = 0;
    int have_code_entry;
    (void)target;

    if (!bc.binname) return -1;
    tap_name = bc.name ? bc.name : "BASECONF";
    if (!*tap_name || strlen(tap_name) > 10) {
        fprintf(stderr, "BaseConf: TAP name must contain 1 to 10 characters\n");
        return -1;
    }
    bank_prefix = bc.bank_prefix ? bc.bank_prefix : "BANK";
    if (!*bank_prefix || strlen(bank_prefix) > 7) {
        fprintf(stderr, "BaseConf: bank prefix must contain 1 to 7 characters\n");
        return -1;
    }
    if (bc.org < -1 || bc.usr_address < -1 || bc.clear_address < -1) {
        fprintf(stderr, "BaseConf: addresses must be non-negative\n");
        return -1;
    }
    if (!bc.crtfile) {
        snprintf(crtname, sizeof(crtname) - 1, "%s", bc.binname);
        suffix_change(crtname, "");
        bc.crtfile = crtname;
    }
    snprintf(mapname, sizeof(mapname) - 1, "%s", bc.crtfile);
    suffix_change(mapname, ".map");
    snprintf(outname, sizeof(outname) - 1, "%s", bc.outfile ? bc.outfile : bc.binname);
    if (!bc.outfile) suffix_change(outname, ".tap");
    if (strcmp(outname, bc.binname) == 0) {
        fprintf(stderr, "BaseConf: input and output file names must differ\n");
        return -1;
    }
    if (!(fmap = fopen(mapname, "r"))) {
        fprintf(stderr, "BaseConf: cannot open map file %s\n", mapname);
        return -1;
    }
    memset(&memory, 0, sizeof(memory));
    memset(&aligned, 0, sizeof(aligned));
    mb_create_bankspace(&memory, "BANK");
    mb_enumerate_banks(fmap, bc.binname, &memory, &aligned);
    have_code_entry = map_symbol_address(fmap, "start", &code_entry) == 0;
    fclose(fmap);
    if (memory.num != 1) {
        fprintf(stderr, "BaseConf: invalid bank-space configuration\n");
        goto done;
    }
    normalize_linker_banks(&memory);
    if (mb_sort_banks(&memory) != 0) goto done;
    if (collect_range(&memory.mainbank, 1, &main_image) <= 0) {
        fprintf(stderr, "BaseConf: no initialized main CODE/DATA image found\n");
        goto done;
    }
    load_org = bc.org >= 0 ? (unsigned)bc.org : main_image.start;
    origin_delta = (int)load_org - (int)main_image.start;
    if ((int)main_image.start + origin_delta < 0 || (int)main_image.end + origin_delta > 0x10000) {
        fprintf(stderr, "BaseConf: --org moves the main image outside the 16-bit address space\n");
        goto done;
    }
    main_image.start = (unsigned)((int)main_image.start + origin_delta);
    main_image.end = (unsigned)((int)main_image.end + origin_delta);
    if (main_image.end - main_image.start > 65533) {
        fprintf(stderr, "BaseConf: main payload is too large for one TAP CODE block\n");
        goto done;
    }
    entry = bc.usr_address >= 0 ? (unsigned)bc.usr_address
            : have_code_entry   ? (unsigned)((int)code_entry + origin_delta)
                                : load_org;
    if (entry > 0xffff || entry < main_image.start || entry >= main_image.end) {
        fprintf(stderr, "BaseConf: entry address 0x%04x is outside the main image\n", entry);
        goto done;
    }
    clear_address = bc.clear_address >= 0 ? bc.clear_address : 0x5fff;
    if (clear_address < 0 || clear_address > 65535) goto done;
    for (i = 0; i < MAXBANKS; ++i) {
        int collected = collect_range(&memory.bankspace[0].membank[i], 0, &banks[i]);
        if (collected < 0) goto done;
        if (collected > 0 && banks[i].end - banks[i].start > 0x4000) {
            fprintf(stderr, "BaseConf: bank %d payload exceeds the 16 KiB window\n", i);
            goto done;
        }
    }
    if (make_basic(basic, sizeof(basic), &basic_length, entry, clear_address, banks) != 0) {
        fprintf(stderr, "BaseConf: BASIC loader exceeds supported size\n");
        goto done;
    }
    out = fopen(outname, "wb");
    if (!out) {
        fprintf(stderr, "BaseConf: cannot create %s\n", outname);
        goto done;
    }
    if (write_basic(out, tap_name, (unsigned char *)basic, basic_length) ||
        write_image(out, tap_name, &main_image)) {
        fclose(out);
        goto done;
    }
    for (i = 0; i < MAXBANKS; ++i) {
        char name[11];
        if (!banks[i].data) continue;
        snprintf(name, sizeof(name), "%s%03d", bank_prefix, i);
        if (write_image(out, name, &banks[i])) {
            fclose(out);
            goto done;
        }
    }
    if (fclose(out) != 0) goto done;
    result = 0;

done:
    free_memory_images(&memory, &main_image, banks);
    mb_cleanup_aligned(&aligned);
    return result;
}
