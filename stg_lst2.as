;;;;;;;;;;;;;;;;;;;
; sample programs ;
;;;;;;;;;;;;;;;;;;;



;初期定義

#define		SHOT_MAX		16		;ショット総数
#define		SHOT_VY			26		;ショット移動量
#define		SHOT_X_SIZE		8		;ショット当たりサイズ
#define		SHOT_Y_SIZE		48

#define		ENEMY_MAX		256		;敵総数
#define		ENEMY_X_MIN		5		;敵移動座標制限
#define		ENEMY_X_MAX		371
#define		ENEMY_Y_MAX		600
#define		ENEMY_X_SIZE	24		;敵当たりサイズ
#define		ENEMY_Y_SIZE	32

#define		SHIP_REMAIN		2		;初期残機数
#define		SHIP_VX			9		;自機移動量
#define		SHIP_VY			4
#define		SHIP_X_MIN		5		;自機移動座標制限
#define		SHIP_X_MAX		371
#define		SHIP_Y_MIN		220
#define		SHIP_Y_MAX		530
#define		SHIP_X_OFFSET	11		;自機当たり位置補正
#define		SHIP_Y_OFFSET	20
#define		SHIP_X_SIZE		2		;自機当たりサイズ
#define		SHIP_Y_SIZE		2

#define		SC_MAX_X		400		;画面サイズ
#define		SC_MAX_Y		600
#define		SCROLL_SPEED	3		;スクロールスピード
#define		STICK_CHECK		31		;stick第2パラメータ(連打制限)



;画面などの重要な初期設定
	gosub *grand_init



;メインループ
*grand_loops
;入力関係
	stick st,STICK_CHECK				;入力統括(終了[Q]のみ一時停止中に取得)
	await 17							;約1/60
	if st&128:pause_flag = 0-pause_flag	;一時停止フラグ
	if pause_flag == -1:if gq == 1:goto *grand_end:else:gosub *pause_loops:goto *grand_jobs								;一時停止と終了処理(esc中に[Q]で終了)
;画面表示、スクロール
	redraw 2
	pos 0,0:gcopy 7,0,scroll_y,SC_MAX_X,SC_MAX_Y	;背景コピー(兼画面消去)
	scroll_y -= scroll_sp
	if scroll_y<0:scroll_y += SC_MAX_Y				;スクロール
;処理分岐(各ルーチンに飛ぶ)
	if game_mode=2:gosub  *game_loops:goto *grand_jobs	;ゲーム中
	if game_mode=3:gosub  *dead_loops:goto *grand_jobs	;死亡中
	if game_mode=1:gosub *start_loops:goto *grand_jobs	;スタート待ち
	if game_mode=4:gosub  *over_loops:goto *grand_jobs	;ゲームオーバー
	if game_mode=0:gosub  *demo_loops					;デモ画面
*grand_jobs
	gosub *score_display	;スコアなど完全表示
	redraw 1
	goto *grand_loops



;終了処理(必要なら)
*grand_end
	end



;ゲーム本体
*game_loops
;入力、自機移動
	if ship_hit != 0:goto *ship_move_skip	;死亡中は入力をスキップ
	vx=(st>>2&1)-(st&1)						;論理式による移動(この手があったか！)
	vy=(st>>3&1)-(st>>1&1)
	ship_x+=vx*SHIP_VX:ship_y+=vy*SHIP_VY	;移動量・位置の補正
	if ship_x<SHIP_X_MIN:ship_x=SHIP_X_MIN
	if ship_x>SHIP_X_MAX:ship_x=SHIP_X_MAX
	if ship_y<SHIP_Y_MIN:ship_y=SHIP_Y_MIN
	if ship_y>SHIP_Y_MAX:ship_y=SHIP_Y_MAX
;★ショット出現
	if st&16:gosub *shot_born					;スペース(ショット出現)
*ship_move_skip
;★ショット移動
	if shot_next_top == -1:goto *shot_loops_end	;ショット存在せず(ループ部素通り)
	sn=shot_next_top							;リスト先頭から
	sp=-1
*shot_move_loops
	dup sx,shot_x.sn
	dup sy,shot_y.sn
	sy -= SHOT_VY								;ショットを上に移動
	color $ff,$ff,$00:pos sx,sy   :mes "I"
	color $99,$99,$33:pos sx,sy+16:mes "!"
	color $33,$33,$66:pos sx,sy+32:mes ":"
	if sy < -48:gosub *shot_erase:else:sp=sn:sn=shot_next.sn	;全部画面外に出た
	if sn != -1:goto *shot_move_loops	;リスト終了まで続ける
*shot_loops_end
	sf=SHOT_MAX-shot_free_top
	color $ff,$ff,$ff:pos 0,0:mes "shot="+sf



;★敵出現
	c++
	if c == ene_born_count:gosub *ene_born:c=0:if ene_born_count > 1:ene_born_count--					;カウンタ比較によって敵出現(最終的には滝のように出てくる)
	if ene_next_top == -1:goto *ene_loops_end	;敵存在せず(ループ素通り)
;★敵移動
	en=ene_next_top	;敵リスト先頭から
	ep=-1
*ene_move_loops
	eh=0			;消去判定フラグ(消去条件が複数あるので、フラグにして対処)
	dup ex,ene_x.en
	dup ey,ene_y.en
	ex += ene_vx.en
	if ex>ENEMY_X_MAX:ene_vx.en = 0-ene_vx.en	;画面横端で反転させる
	if ex<ENEMY_X_MIN:ene_vx.en = 0-ene_vx.en
	ey += ene_vy.en
	ex2 = ex+ENEMY_X_SIZE	;当たり判定用:大きさを加味した座標
	ey2 = ey+ENEMY_Y_SIZE
	if ene_vy.en == 0:color $ff,$00,$ff:else:color $00,$ff,$ff	;死亡中は紫色
			;自機にあたった場合以外でvyが0になることはない(暫定措置)
	pos ex,ey   :mes "xWx"
	pos ex,ey+16:mes "^Y^"

;★ショットとの当たり判定
	if shot_next_top == -1:goto *ene_hit_loops_end	;ショットがなければ無視
	sn=shot_next_top	;ショット・リスト先頭から
	sp=-1
*ene_hit_loops
	dup sx,shot_x.sn
	dup sy,shot_y.sn
	sx2 = sx+SHOT_X_SIZE	;当たり判定用座標(ショット)
	sy2 = sy+SHOT_Y_SIZE
	if ex>sx2:goto *ene_nohit	;比較(矩形角位置の比較・分離バージョン)
	if sx>ex2:goto *ene_nohit
	if ey>sy2:goto *ene_nohit
	if sy>ey2:goto *ene_nohit
	eh++:score += ene_sc.en		;当たり(スコア加算、敵消去、ショット消去)
	gosub *shot_erase
	goto *ene_hit_checked
*ene_nohit
	sp=sn:sn=shot_next.sn		;ハズレ(次を検索)
*ene_hit_checked
	if sn != -1:goto *ene_hit_loops	;ショットリスト終了まで続ける
*ene_hit_loops_end

;自機との当たり判定
	if ship_hit != 0:goto *ene_ship_nohit
	ship_x1 = ship_x+SHIP_X_OFFSET				;自機は真ん中4x4ドットに判定
	ship_x2 = ship_x+SHIP_X_OFFSET+SHIP_X_SIZE
	ship_y1 = ship_y+SHIP_Y_OFFSET
	ship_y2 = ship_y+SHIP_Y_OFFSET+SHIP_Y_SIZE
	if ex>ship_x2 :goto *ene_ship_nohit	;比較(矩形角位置の比較・分離バージョン)
	if ship_x1>ex2:goto *ene_ship_nohit
	if ey>ship_y2 :goto *ene_ship_nohit
	if ship_y1>ey2:goto *ene_ship_nohit
	ship_hit=1:ene_vx.en = 0:ene_vy.en = 0:gmode 2:scroll_sp=0	;当たり(自機死亡など)
*ene_ship_nohit
	if ey>ENEMY_Y_MAX:eh++				;画面下から消えた
	if eh != 0:gosub *ene_erase:else:ep=en:en=ene_next.en	;条件が揃えば敵消去
	if en != -1:goto *ene_move_loops	;敵リスト最後まで繰り返し
*ene_loops_end
	ef=ENEMY_MAX-ene_free_top
	color $ff,$ff,$ff:pos 0,20:mes "enemy="+ef


;自機表示(爆)
	if ship_hit == 0:color $ff,$ff,$ff:goto *ship_nohit_disp	;死亡中は赤
	repeat 20							;星を散らしてみる(意味はない)
		rnd x,SC_MAX_X:rnd y,SC_MAX_Y
		x -= 8:y -= 16
		rnd r,$100:rnd g,$100:rnd b,$100
		color r,g,b:pos x,y:mes "*"
	loop
	ship_hit++							;死亡カウンタ
	color $ff,$00,$00
	if ship_hit == 150:game_mode=3:c=0	;再スタートへの準備
*ship_nohit_disp
	pos ship_x+8,ship_y   :mes  "A"
	pos ship_x  ,ship_y+16:mes "I#I"

	return



;★ショット出現(サブルーチン)
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

;★ショット消去(サブルーチン)
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



;★敵出現(サブルーチン)
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

;★敵消去(サブルーチン)
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



;スコアなど表示
*score_display
	font "ＭＳ 明朝",16
	if score > high:high=score	;ハイスコア比較
	color $33,$33,$ff
	pos 21,551:mes "score:"+score+"00"
	pos 21,571:mes " high:"+high+"00"
	pos 301,551:mes "remain:"+remain

	color $ff,$ff,$80
	pos 20,550:mes "score:"+score+"00"
	pos 20,570:mes " high:"+high+"00"
	pos 300,550:mes "remain:"+remain
	font "ＭＳ ゴシック",16
	return



;ゲーム開始画面
*start_loops
	rnd x,10:rnd y,20
	rnd r,$100:rnd g,$100:rnd b,$100
	font "ＭＳ 明朝",16
	color r,g,b:pos 120+x,230+y:mes "left "+remain+" fighter."
	c++
	if c == 80:game_mode=2:c=0
	return



;死亡処理
*dead_loops
	ship_hit=0
;	repeat 20							;星を散らしてみる(意味はない)
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
	if remain < 0:remain++:game_mode=4:else:gmode 1:game_mode=1	;残機0ならゲームオーバー、そうでなければ再スタート
	return



;ゲームオーバー画面
*over_loops
	color $33,$33,$33:boxf 0,300,400,340
	rnd x,20:rnd y,20
	rnd r,$100:rnd g,$100:rnd b,$100
	color r,g,b:pos 130+x,302+y:mes "game over."
	c++
	if st&32:c=180						;[enter]で画面スキップ
	if c == 180:c=0:game_mode=0:gmode 1	;デモ画面に戻る
	return



;デモ画面
*demo_loops
	font "ＭＳ 明朝",16
	color $ff,$ff,$ff
	pos  20, 40:mes "play instructions."
	color $ff,$ff,$00
	pos  50, 60:mes "  ↑  "
	pos  50, 76:mes "←↓→ ... fighter moved."
	pos  50, 96:mes "[Space]... shots fired rapidly."


	rnd r,$80:rnd g,$80:rnd b,$80
	color r,g,b:boxf 0,440,400,480
	color $00,$00,$ff
	pos  15,450:mes "(c)1999 Circle-AY Design,All rights reserved."
	color $ff,$ff,$00
	pos  14,449:mes "(c)1999 Circle-AY Design,All rights reserved."

	rnd x,10:rnd y,20
	rnd r,$100:rnd g,$100:rnd b,$100
	font "ＭＳ 明朝",16
	color r,g,b:pos 120+x,230+y:mes "press [Enter] key."

	if st&32:gosub *game_init_first	;[enter]でゲーム開始
	return



;一時停止
*pause_loops
	getkey gq,'Q'		;終了キーの取得(どうせ一時停止中しか効かない)
	color $ff,$ff,$ff
	boxf 0,300,400,340
	rnd x,20:rnd y,20
	rnd r,$100:rnd g,$100:rnd b,$100
	color r,g,b:pos 150+x,302+y:mes "paused."
	return



;ゲーム初期設定(ゲーム開始時)
*game_init_first
	gosub *game_init
	ene_born_count = 60			;出現間隔
	remain = SHIP_REMAIN		;残機数
	score = 0					;得点

	return


；ゲーム初期設定
*game_init
	font "ＭＳ ゴシック",16
	game_mode = 1				;ゲームスタート状態
	c=0							;汎用カウンタ(主にタイミング取り)
	scroll_sp = SCROLL_SPEED	;スクロール速度

;ショット関係
	repeat SHOT_MAX				;リスト初期化
		shot_next.cnt = -1
		shot_free.cnt = cnt
	loop
	shot_next_top = -1
	shot_free_top = SHOT_MAX

;敵関係
	repeat ENEMY_MAX			;リスト初期化
		ene_next.cnt = -1
		ene_free.cnt = cnt
	loop
	ene_next_top = -1
	ene_free_top = ENEMY_MAX

;自機関係
	ship_x = 188				;座標
	ship_y = 530
	ship_hit = 0				;死亡フラグ

	return



;全体の初期設定
*grand_init
;変数初期化
;ショット関係
	dim shot_x,SHOT_MAX			;座標
	dim shot_y,SHOT_MAX
	dim shot_next,SHOT_MAX		;リスト用
	dim shot_free,SHOT_MAX

;敵関係
	dim ene_x,ENEMY_MAX			;座標
	dim ene_y,ENEMY_MAX
	dim ene_vx,ENEMY_MAX		;移動量
	dim ene_vy,ENEMY_MAX
	dim ene_sc,ENEMY_MAX		;得点
	dim ene_next,ENEMY_MAX		;リスト用
	dim ene_free,ENEMY_MAX

;その他、主に雑用
	scroll_y = 0				;スクロール画面位置
	scroll_sp = SCROLL_SPEED	;スクロール速度
	game_mode = 0				;ゲーム状態フラグ(メインルーチン参照)
	high = 10000				;最高得点
	pause_flag = 1				;一時停止フラグ(-1:一時停止)



;画面初期化
	screen 0,SC_MAX_X,SC_MAX_Y,1,0,0,SC_MAX_X,SC_MAX_Y	;id0:表示面
	title "stg_lst2:サンプル用シューティング"
	cls 4

	buffer 7,SC_MAX_X,SC_MAX_Y*2,1						;id7:背景の星
	cls 4

	repeat 1600											;背景の星を表示
		rnd x,SC_MAX_X:rnd y,SC_MAX_Y
		rnd r,$100:rnd g,$100:rnd b,$100
		color r,g,b:pset x,y
	loop
	pos 0,SC_MAX_Y:gcopy 7,0,0,SC_MAX_X,SC_MAX_Y

	gsel 0												;すべてid2に描画
	gmode 1,SC_MAX_X,SC_MAX_Y

	font "ＭＳ ゴシック",16

	return



	end
;;;;;;;;;;;;;;;;;;;;;;;;;;
; end of sample programs ;
;;;;;;;;;;;;;;;;;;;;;;;;;;
