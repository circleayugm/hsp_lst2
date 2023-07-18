;;;;;;;;;;;;;;;;;;;
; sample programs ;
;;;;;;;;;;;;;;;;;;;



;������`

#define		SHOT_MAX		16		;�V���b�g����
#define		SHOT_VY			26		;�V���b�g�ړ���
#define		SHOT_X_SIZE		8		;�V���b�g������T�C�Y
#define		SHOT_Y_SIZE		48

#define		ENEMY_MAX		256		;�G����
#define		ENEMY_X_MIN		5		;�G�ړ����W����
#define		ENEMY_X_MAX		371
#define		ENEMY_Y_MAX		600
#define		ENEMY_X_SIZE	24		;�G������T�C�Y
#define		ENEMY_Y_SIZE	32

#define		SHIP_REMAIN		2		;�����c�@��
#define		SHIP_VX			9		;���@�ړ���
#define		SHIP_VY			4
#define		SHIP_X_MIN		5		;���@�ړ����W����
#define		SHIP_X_MAX		371
#define		SHIP_Y_MIN		220
#define		SHIP_Y_MAX		530
#define		SHIP_X_OFFSET	11		;���@������ʒu�␳
#define		SHIP_Y_OFFSET	20
#define		SHIP_X_SIZE		2		;���@������T�C�Y
#define		SHIP_Y_SIZE		2

#define		SC_MAX_X		400		;��ʃT�C�Y
#define		SC_MAX_Y		600
#define		SCROLL_SPEED	3		;�X�N���[���X�s�[�h
#define		STICK_CHECK		31		;stick��2�p�����[�^(�A�Ő���)



;��ʂȂǂ̏d�v�ȏ����ݒ�
	gosub *grand_init



;���C�����[�v
*grand_loops
;���͊֌W
	stick st,STICK_CHECK				;���͓���(�I��[Q]�݈̂ꎞ��~���Ɏ擾)
	await 17							;��1/60
	if st&128:pause_flag = 0-pause_flag	;�ꎞ��~�t���O
	if pause_flag == -1:if gq == 1:goto *grand_end:else:gosub *pause_loops:goto *grand_jobs								;�ꎞ��~�ƏI������(esc����[Q]�ŏI��)
;��ʕ\���A�X�N���[��
	redraw 2
	pos 0,0:gcopy 7,0,scroll_y,SC_MAX_X,SC_MAX_Y	;�w�i�R�s�[(����ʏ���)
	scroll_y -= scroll_sp
	if scroll_y<0:scroll_y += SC_MAX_Y				;�X�N���[��
;��������(�e���[�`���ɔ��)
	if game_mode=2:gosub  *game_loops:goto *grand_jobs	;�Q�[����
	if game_mode=3:gosub  *dead_loops:goto *grand_jobs	;���S��
	if game_mode=1:gosub *start_loops:goto *grand_jobs	;�X�^�[�g�҂�
	if game_mode=4:gosub  *over_loops:goto *grand_jobs	;�Q�[���I�[�o�[
	if game_mode=0:gosub  *demo_loops					;�f�����
*grand_jobs
	gosub *score_display	;�X�R�A�ȂǊ��S�\��
	redraw 1
	goto *grand_loops



;�I������(�K�v�Ȃ�)
*grand_end
	end



;�Q�[���{��
*game_loops
;���́A���@�ړ�
	if ship_hit != 0:goto *ship_move_skip	;���S���͓��͂��X�L�b�v
	vx=(st>>2&1)-(st&1)						;�_�����ɂ��ړ�(���̎肪���������I)
	vy=(st>>3&1)-(st>>1&1)
	ship_x+=vx*SHIP_VX:ship_y+=vy*SHIP_VY	;�ړ��ʁE�ʒu�̕␳
	if ship_x<SHIP_X_MIN:ship_x=SHIP_X_MIN
	if ship_x>SHIP_X_MAX:ship_x=SHIP_X_MAX
	if ship_y<SHIP_Y_MIN:ship_y=SHIP_Y_MIN
	if ship_y>SHIP_Y_MAX:ship_y=SHIP_Y_MAX
;���V���b�g�o��
	if st&16:gosub *shot_born					;�X�y�[�X(�V���b�g�o��)
*ship_move_skip
;���V���b�g�ړ�
	if shot_next_top == -1:goto *shot_loops_end	;�V���b�g���݂���(���[�v���f�ʂ�)
	sn=shot_next_top							;���X�g�擪����
	sp=-1
*shot_move_loops
	dup sx,shot_x.sn
	dup sy,shot_y.sn
	sy -= SHOT_VY								;�V���b�g����Ɉړ�
	color $ff,$ff,$00:pos sx,sy   :mes "I"
	color $99,$99,$33:pos sx,sy+16:mes "!"
	color $33,$33,$66:pos sx,sy+32:mes ":"
	if sy < -48:gosub *shot_erase:else:sp=sn:sn=shot_next.sn	;�S����ʊO�ɏo��
	if sn != -1:goto *shot_move_loops	;���X�g�I���܂ő�����
*shot_loops_end
	sf=SHOT_MAX-shot_free_top
	color $ff,$ff,$ff:pos 0,0:mes "shot="+sf



;���G�o��
	c++
	if c == ene_born_count:gosub *ene_born:c=0:if ene_born_count > 1:ene_born_count--					;�J�E���^��r�ɂ���ēG�o��(�ŏI�I�ɂ͑�̂悤�ɏo�Ă���)
	if ene_next_top == -1:goto *ene_loops_end	;�G���݂���(���[�v�f�ʂ�)
;���G�ړ�
	en=ene_next_top	;�G���X�g�擪����
	ep=-1
*ene_move_loops
	eh=0			;��������t���O(������������������̂ŁA�t���O�ɂ��đΏ�)
	dup ex,ene_x.en
	dup ey,ene_y.en
	ex += ene_vx.en
	if ex>ENEMY_X_MAX:ene_vx.en = 0-ene_vx.en	;��ʉ��[�Ŕ��]������
	if ex<ENEMY_X_MIN:ene_vx.en = 0-ene_vx.en
	ey += ene_vy.en
	ex2 = ex+ENEMY_X_SIZE	;�����蔻��p:�傫���������������W
	ey2 = ey+ENEMY_Y_SIZE
	if ene_vy.en == 0:color $ff,$00,$ff:else:color $00,$ff,$ff	;���S���͎��F
			;���@�ɂ��������ꍇ�ȊO��vy��0�ɂȂ邱�Ƃ͂Ȃ�(�b��[�u)
	pos ex,ey   :mes "xWx"
	pos ex,ey+16:mes "^Y^"

;���V���b�g�Ƃ̓����蔻��
	if shot_next_top == -1:goto *ene_hit_loops_end	;�V���b�g���Ȃ���Ζ���
	sn=shot_next_top	;�V���b�g�E���X�g�擪����
	sp=-1
*ene_hit_loops
	dup sx,shot_x.sn
	dup sy,shot_y.sn
	sx2 = sx+SHOT_X_SIZE	;�����蔻��p���W(�V���b�g)
	sy2 = sy+SHOT_Y_SIZE
	if ex>sx2:goto *ene_nohit	;��r(��`�p�ʒu�̔�r�E�����o�[�W����)
	if sx>ex2:goto *ene_nohit
	if ey>sy2:goto *ene_nohit
	if sy>ey2:goto *ene_nohit
	eh++:score += ene_sc.en		;������(�X�R�A���Z�A�G�����A�V���b�g����)
	gosub *shot_erase
	goto *ene_hit_checked
*ene_nohit
	sp=sn:sn=shot_next.sn		;�n�Y��(��������)
*ene_hit_checked
	if sn != -1:goto *ene_hit_loops	;�V���b�g���X�g�I���܂ő�����
*ene_hit_loops_end

;���@�Ƃ̓����蔻��
	if ship_hit != 0:goto *ene_ship_nohit
	ship_x1 = ship_x+SHIP_X_OFFSET				;���@�͐^��4x4�h�b�g�ɔ���
	ship_x2 = ship_x+SHIP_X_OFFSET+SHIP_X_SIZE
	ship_y1 = ship_y+SHIP_Y_OFFSET
	ship_y2 = ship_y+SHIP_Y_OFFSET+SHIP_Y_SIZE
	if ex>ship_x2 :goto *ene_ship_nohit	;��r(��`�p�ʒu�̔�r�E�����o�[�W����)
	if ship_x1>ex2:goto *ene_ship_nohit
	if ey>ship_y2 :goto *ene_ship_nohit
	if ship_y1>ey2:goto *ene_ship_nohit
	ship_hit=1:ene_vx.en = 0:ene_vy.en = 0:gmode 2:scroll_sp=0	;������(���@���S�Ȃ�)
*ene_ship_nohit
	if ey>ENEMY_Y_MAX:eh++				;��ʉ����������
	if eh != 0:gosub *ene_erase:else:ep=en:en=ene_next.en	;�����������ΓG����
	if en != -1:goto *ene_move_loops	;�G���X�g�Ō�܂ŌJ��Ԃ�
*ene_loops_end
	ef=ENEMY_MAX-ene_free_top
	color $ff,$ff,$ff:pos 0,20:mes "enemy="+ef


;���@�\��(��)
	if ship_hit == 0:color $ff,$ff,$ff:goto *ship_nohit_disp	;���S���͐�
	repeat 20							;�����U�炵�Ă݂�(�Ӗ��͂Ȃ�)
		rnd x,SC_MAX_X:rnd y,SC_MAX_Y
		x -= 8:y -= 16
		rnd r,$100:rnd g,$100:rnd b,$100
		color r,g,b:pos x,y:mes "*"
	loop
	ship_hit++							;���S�J�E���^
	color $ff,$00,$00
	if ship_hit == 150:game_mode=3:c=0	;�ăX�^�[�g�ւ̏���
*ship_nohit_disp
	pos ship_x+8,ship_y   :mes  "A"
	pos ship_x  ,ship_y+16:mes "I#I"

	return



;���V���b�g�o��(�T�u���[�`��)
*shot_born
	if shot_free_top == 0:return

	sp = shot_free_top-1
	sn = shot_free.sp
	shot_free.sp = -1

	shot_x.sn = ship_x+8
	shot_y.sn = ship_y

	if shot_next_top == -1:shot_next.sn = -1:else:shot_next.sn = shot_next_top
	shot_next_top = sn
	shot_free_top--

	return

;���V���b�g����(�T�u���[�`��)
*shot_erase
	shot_free.shot_free_top = sn
	shot_free_top++
	if shot_next.sn == -1:goto *erase_shot_lastdata
	if sp == -1:shot_next_top = shot_next.sn:else:shot_next.sp = shot_next.sn
	sn = shot_next.sn
	return
*erase_shot_lastdata
	if sp == -1:shot_next_top = -1:else:shot_next.sp = -1
	sn = -1
	return



;���G�o��(�T�u���[�`��)
*ene_born
	if ene_free_top == 0:return

	ep = ene_free_top-1
	en = ene_free.ep
	ene_free.ep = -1

	rnd ene_x.en,366:ene_x.en += 5
	ene_y.en = -32
	rnd ene_vx.en,14:ene_vx.en -= 8
	rnd ene_vy.en,10:ene_vy.en += 2
	ene_sc.en = ene_vx.en:if ene_sc.en < 0:ene_sc.en = 0 - ene_sc.en
	ene_sc.en = ene_sc.en * ene_vy.en
	ene_sc.en += 1

	if ene_next_top == -1:ene_next.en = -1:else:ene_next.en = ene_next_top
	ene_next_top = en
	ene_free_top--

	return

;���G����(�T�u���[�`��)
*ene_erase
	ene_free.ene_free_top = en
	ene_free_top++
	if ene_next.en == -1:goto *erase_ene_lastdata
	if ep == -1:ene_next_top = ene_next.en:else:ene_next.ep = ene_next.en
	en = ene_next.en
	return
*erase_ene_lastdata
	if ep == -1:ene_next_top = -1:else:ene_next.ep = -1
	en = -1
	return



;�X�R�A�ȂǕ\��
*score_display
	font "�l�r ����",16
	if score > high:high=score	;�n�C�X�R�A��r
	color $33,$33,$ff
	pos 21,551:mes "score:"+score+"00"
	pos 21,571:mes " high:"+high+"00"
	pos 301,551:mes "remain:"+remain

	color $ff,$ff,$80
	pos 20,550:mes "score:"+score+"00"
	pos 20,570:mes " high:"+high+"00"
	pos 300,550:mes "remain:"+remain
	font "�l�r �S�V�b�N",16
	return



;�Q�[���J�n���
*start_loops
	rnd x,10:rnd y,20
	rnd r,$100:rnd g,$100:rnd b,$100
	font "�l�r ����",16
	color r,g,b:pos 120+x,230+y:mes "left "+remain+" fighter."
	c++
	if c == 80:game_mode=2:c=0
	return



;���S����
*dead_loops
	ship_hit=0
;	repeat 20							;�����U�炵�Ă݂�(�Ӗ��͂Ȃ�)
;		rnd x,SC_MAX_X:rnd y,SC_MAX_Y
;		x -= 8:y -= 16
;		rnd r,$100:rnd g,$100:rnd b,$100
;		color r,g,b:pos x,y:mes "*"
;	loop
;	color $ff,$00,$00
;	pos ship_x,ship_y   :mes " A"
;	pos ship_x,ship_y+16:mes "I#I"
;	c++
	c=0:remain--:gosub *game_init
	if remain < 0:remain++:game_mode=4:else:gmode 1:game_mode=1	;�c�@0�Ȃ�Q�[���I�[�o�[�A�����łȂ���΍ăX�^�[�g
	return



;�Q�[���I�[�o�[���
*over_loops
	color $33,$33,$33:boxf 0,300,400,340
	rnd x,20:rnd y,20
	rnd r,$100:rnd g,$100:rnd b,$100
	color r,g,b:pos 130+x,302+y:mes "game over."
	c++
	if st&32:c=180						;[enter]�ŉ�ʃX�L�b�v
	if c == 180:c=0:game_mode=0:gmode 1	;�f����ʂɖ߂�
	return



;�f�����
*demo_loops
	font "�l�r ����",16
	color $ff,$ff,$ff
	pos  20, 40:mes "play instructions."
	color $ff,$ff,$00
	pos  50, 60:mes "  ��  "
	pos  50, 76:mes "������ ... fighter moved."
	pos  50, 96:mes "[Space]... shots fired rapidly."


	rnd r,$80:rnd g,$80:rnd b,$80
	color r,g,b:boxf 0,440,400,480
	color $00,$00,$ff
	pos  15,450:mes "(c)1999 Circle-AY Design,All rights reserved."
	color $ff,$ff,$00
	pos  14,449:mes "(c)1999 Circle-AY Design,All rights reserved."

	rnd x,10:rnd y,20
	rnd r,$100:rnd g,$100:rnd b,$100
	font "�l�r ����",16
	color r,g,b:pos 120+x,230+y:mes "press [Enter] key."

	if st&32:gosub *game_init_first	;[enter]�ŃQ�[���J�n
	return



;�ꎞ��~
*pause_loops
	getkey gq,'Q'		;�I���L�[�̎擾(�ǂ����ꎞ��~�����������Ȃ�)
	color $ff,$ff,$ff
	boxf 0,300,400,340
	rnd x,20:rnd y,20
	rnd r,$100:rnd g,$100:rnd b,$100
	color r,g,b:pos 150+x,302+y:mes "paused."
	return



;�Q�[�������ݒ�(�Q�[���J�n��)
*game_init_first
	gosub *game_init
	ene_born_count = 60			;�o���Ԋu
	remain = SHIP_REMAIN		;�c�@��
	score = 0					;���_

	return


�G�Q�[�������ݒ�
*game_init
	font "�l�r �S�V�b�N",16
	game_mode = 1				;�Q�[���X�^�[�g���
	c=0							;�ėp�J�E���^(��Ƀ^�C�~���O���)
	scroll_sp = SCROLL_SPEED	;�X�N���[�����x

;�V���b�g�֌W
	repeat SHOT_MAX				;���X�g������
		shot_next.cnt = -1
		shot_free.cnt = cnt
	loop
	shot_next_top = -1
	shot_free_top = SHOT_MAX

;�G�֌W
	repeat ENEMY_MAX			;���X�g������
		ene_next.cnt = -1
		ene_free.cnt = cnt
	loop
	ene_next_top = -1
	ene_free_top = ENEMY_MAX

;���@�֌W
	ship_x = 188				;���W
	ship_y = 530
	ship_hit = 0				;���S�t���O

	return



;�S�̂̏����ݒ�
*grand_init
;�ϐ�������
;�V���b�g�֌W
	dim shot_x,SHOT_MAX			;���W
	dim shot_y,SHOT_MAX
	dim shot_next,SHOT_MAX		;���X�g�p
	dim shot_free,SHOT_MAX

;�G�֌W
	dim ene_x,ENEMY_MAX			;���W
	dim ene_y,ENEMY_MAX
	dim ene_vx,ENEMY_MAX		;�ړ���
	dim ene_vy,ENEMY_MAX
	dim ene_sc,ENEMY_MAX		;���_
	dim ene_next,ENEMY_MAX		;���X�g�p
	dim ene_free,ENEMY_MAX

;���̑��A��ɎG�p
	scroll_y = 0				;�X�N���[����ʈʒu
	scroll_sp = SCROLL_SPEED	;�X�N���[�����x
	game_mode = 0				;�Q�[����ԃt���O(���C�����[�`���Q��)
	high = 10000				;�ō����_
	pause_flag = 1				;�ꎞ��~�t���O(-1:�ꎞ��~)



;��ʏ�����
	screen 0,SC_MAX_X,SC_MAX_Y,1,0,0,SC_MAX_X,SC_MAX_Y	;id0:�\����
	title "stg_lst2:�T���v���p�V���[�e�B���O"
	cls 4

	buffer 7,SC_MAX_X,SC_MAX_Y*2,1						;id7:�w�i�̐�
	cls 4

	repeat 1600											;�w�i�̐���\��
		rnd x,SC_MAX_X:rnd y,SC_MAX_Y
		rnd r,$100:rnd g,$100:rnd b,$100
		color r,g,b:pset x,y
	loop
	pos 0,SC_MAX_Y:gcopy 7,0,0,SC_MAX_X,SC_MAX_Y

	gsel 0												;���ׂ�id2�ɕ`��
	gmode 1,SC_MAX_X,SC_MAX_Y

	font "�l�r �S�V�b�N",16

	return



	end
;;;;;;;;;;;;;;;;;;;;;;;;;;
; end of sample programs ;
;;;;;;;;;;;;;;;;;;;;;;;;;;
