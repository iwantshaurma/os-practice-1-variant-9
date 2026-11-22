org 7C00h
        jmp     start
line1:  db 08Ah, 080h, 099h, 080h, 090h, 088h, 08Dh, 080h
        db 020h
        db 082h, 088h, 08Ah, 092h, 08Eh, 090h, 088h, 09Ah
        db 0
line1_len = $ - line1 - 1
line2:  db 08Ch, 080h, 08Ah, 091h, 088h, 08Ch, 08Eh, 082h, 08Dh, 080h
        db 020h
        db 08Dh, 08Ch, 092h, 096h, 087h, 089h, 087h, 095h, 081h, 083h
        db 0
line2_len = $ - line2 - 1
start:
        cli
        xor     ax, ax
        mov     ds, ax
        mov     es, ax
        mov     ss, ax
        mov     sp, 7C00h
        sti
        cld
        mov     [bootdrv], dl
        mov     ax, 1
        test    dl, 80h
        jz      .lba
        mov     ax, 2049
.lba:
        mov     [dap+8], ax
        mov     si, dap
        mov     dl, [bootdrv]
        mov     ah, 42h
        int     13h
        jnc     .fontok
        mov     ax, 0201h
        mov     cx, 2
        mov     dh, 0
        mov     bx, 500h
        mov     dl, [bootdrv]
        int     13h
        jc      .nofont
.fontok:
        mov     ax, 0013h
        int     10h
        mov     ax, 0A000h
        mov     es, ax
        mov     al, 04h
        mov     dx, 154
        mov     bp, 40
        call    fill_plate
        mov     si, line1
        mov     cx, 312 - line1_len*8
        mov     dx, 158
        mov     bl, 0Eh
        call    print_str
        mov     si, line2
        mov     cx, 312 - line2_len*8
        mov     dx, 176
        mov     bl, 0Eh
        call    print_str
        call    draw_triangle
        xor     ah, ah
        int     16h
        int     19h
.nofont:
        int     18h
fill_plate:
        push    ax
        push    cx
        push    di
.row:
        imul    di, dx, 320
        add     di, 136
        mov     cx, 180
        rep     stosb
        inc     dx
        dec     bp
        jnz     .row
        pop     di
        pop     cx
        pop     ax
        ret
plot_pixel:
        push    di
        imul    di, dx, 320
        add     di, cx
        mov     [es:di], al
        pop     di
        ret
draw_triangle:
        mov     al, 0Ah
        mov     bx, 0
.sides:
        mov     dx, 16
        add     dx, bx
        push    ax
        mov     ax, bx
        imul    ax, 35
        mov     cl, 60
        div     cl
        movzx   si, al
        pop     ax
        mov     cx, 55
        sub     cx, si
        call    plot_pixel
        mov     cx, 55
        add     cx, si
        call    plot_pixel
        inc     bx
        cmp     bx, 60
        jle     .sides
        mov     dx, 76
        mov     cx, 20
.base:
        call    plot_pixel
        inc     cx
        cmp     cx, 90
        jle     .base
        ret
print_str:
        push    ax
        push    di
        push    bp
.next:
        mov     al, [si]
        inc     si
        test    al, al
        jz      .done
        cmp     al, 20h
        jne     .glyph
        add     cx, 8
        jmp     .next
.glyph:
        sub     al, 80h
        xor     ah, ah
        mov     di, ax
        shl     di, 4
        add     di, 500h
        mov     bp, 16
        push    dx
.row:
        mov     ah, [di]
        inc     di
        push    cx
        push    bp
        mov     bp, 8
.bit:
        test    ah, 80h
        jz      .skip
        mov     al, bl
        call    plot_pixel
.skip:
        shl     ah, 1
        inc     cx
        dec     bp
        jnz     .bit
        pop     bp
        pop     cx
        inc     dx
        dec     bp
        jnz     .row
        pop     dx
        add     cx, 8
        jmp     .next
.done:
        pop     bp
        pop     di
        pop     ax
        ret
bootdrv: db 0
dap:    db 10h, 0
        dw 1
        dw 500h, 0
        dq 1
        db 510-($-$$) dup 0
        dw 0AA55h
