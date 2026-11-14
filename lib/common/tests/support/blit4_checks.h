/* Fixed pixel oracles shared by the two native packed4 backends. */
static const uint8_t pixels4[] = {0x01,0x23,0x4f,0xaa, 0x89,0xab,0xcf,0xbb, 0xde,0xf0,0x1f,0xcc};
static const zx_bitmap4_t image4 = {pixels4,5,3,4};
static void expect_pixel(uint16_t x, uint16_t y, uint8_t expected) {
    uint8_t actual=0xff;
    ZX_ASSERT(zx_read_pixel_index(x,y,&actual)==ZX_OK);
    ZX_ASSERT(actual==expected);
}
static void clear_test_row(uint16_t y) {
    zx_set_ink(6); zx_draw_hline(0,31,y);
}
static void check_blit_pixels(void) {
    uint8_t x, key;
    static const uint8_t all[] = {0x01,0x23,0x45,0x67,0x89,0xab,0xcd,0xef};
    const zx_bitmap4_t ramp = {all,16,1,8};
    const zx_bitmap4_t edge = {pixels4,5,1,4};
    clear_test_row(10); clear_test_row(11); clear_test_row(12);
    zx_set_ink(7); zx_set_paper(8);
    ZX_ASSERT(zx_blit4(&image4,1,10)==ZX_OK);
    expect_pixel(0,10,6); expect_pixel(1,10,0); expect_pixel(2,10,1);
    expect_pixel(5,10,4); expect_pixel(6,10,6);
    expect_pixel(1,11,8); expect_pixel(5,11,12);
    expect_pixel(1,12,13); expect_pixel(5,12,1);
    /* An operation after blit observes the original drawing ink. */
    zx_draw_plot(20,10); expect_pixel(20,10,7);
    zx_test_step_marker("opaque-odd-stride");
    clear_test_row(0); clear_test_row(1);
    ZX_ASSERT(zx_blit4(&image4,-1,-1)==ZX_OK);
    expect_pixel(0,0,9); expect_pixel(1,0,10); expect_pixel(2,0,11);
    expect_pixel(3,0,12); expect_pixel(4,0,6);
    expect_pixel(0,1,14); expect_pixel(1,1,15); expect_pixel(2,1,0); expect_pixel(3,1,1);
    ZX_ASSERT(zx_blit4(&image4,-32768,-32768)==ZX_OK);
    ZX_ASSERT(zx_blit4(&image4,32767,32767)==ZX_OK);
    zx_set_ink(6); zx_draw_hline(SCREEN_WIDTH-4,SCREEN_WIDTH-1,SCREEN_HEIGHT-1);
    ZX_ASSERT(zx_blit4(&image4,SCREEN_WIDTH-3,SCREEN_HEIGHT-1)==ZX_OK);
    expect_pixel(SCREEN_WIDTH-4,SCREEN_HEIGHT-1,6);
    expect_pixel(SCREEN_WIDTH-3,SCREEN_HEIGHT-1,0);
    expect_pixel(SCREEN_WIDTH-1,SCREEN_HEIGHT-1,2);
    zx_test_step_marker("clipped-edges");
    /* Exercise every source/destination phase, including ATM page/plane changes. */
    for (x=0;x<8;++x) {
        clear_test_row(20);
        ZX_ASSERT(zx_blit4(&edge,x,20)==ZX_OK);
        if(x) expect_pixel(x-1,20,6);
        expect_pixel(x,20,0); expect_pixel(x+4,20,4); expect_pixel(x+5,20,6);
    }
    for(key=0;key<16;++key) {
        clear_test_row(21);
        ZX_ASSERT(zx_blit4_key(&ramp,1,21,key)==ZX_OK);
        for(x=0;x<16;++x) expect_pixel(x+1,21,x==key?6:x);
        expect_pixel(0,21,6); expect_pixel(17,21,6);
    }
    clear_test_row(0);
    ZX_ASSERT(zx_blit4_key(&image4,-1,-1,10)==ZX_OK);
    expect_pixel(0,0,9); expect_pixel(1,0,6); expect_pixel(2,0,11); expect_pixel(3,0,12);
    zx_test_step_marker("all-keys-and-phases");
}
static void check_blit_arguments(void) {
    zx_bitmap4_t bad=image4;
    ZX_ASSERT(zx_blit4(0,0,0)==ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_blit4_key(&image4,0,0,16)==ZX_INVALID_ARGUMENT);
    bad.stride=2; ZX_ASSERT(zx_blit4(&bad,0,0)==ZX_INVALID_ARGUMENT);
    bad=image4; bad.pixels=0; ZX_ASSERT(zx_blit4(&bad,0,0)==ZX_INVALID_ARGUMENT);
    bad.pixels=(const uint8_t *)0xfffe; ZX_ASSERT(zx_blit4(&bad,0,0)==ZX_INVALID_ARGUMENT);
    bad=image4; bad.height=0xffff; ZX_ASSERT(zx_blit4(&bad,0,0)==ZX_INVALID_ARGUMENT);
    bad.pixels=0; bad.width=0; ZX_ASSERT(zx_blit4(&bad,0,0)==ZX_OK);
    zx_test_step_marker("invalid-and-empty");
}
