# Narrator lines still needing recordings

All 52 team recordings are wired. These cues are subtitle-only until recorded (cue files in `game/narration/<id>.tres`; drop an .ogg in `game/assets/audio/narrator/voice/` and set the cue's `stream`).

## From the script but not recorded
- Lights out #2 line 4: "And your options are..." (add a cue and put it in `QUESTION_CUES` in `gargoyle_gate.gd`)
- `quiz_phone_friend` (Lights out #2 line 14): "Nice try, you don't have any friends."

## Needs a re-take?
- `keypad_right` / `lights_out_3_4.ogg` is only 2.5 s for an 85-character line — probably cut short.

## Placeholder lines (not in the script; write + record, or keep as text)
- Ads: ads_first, ads_type_nudge, ads_wave_2, ads_decoy, ads_nested, ads_runner, ads_countdown, ads_eco
- Antivirus: av_offer_intro, av_no_x, av_no_x_again, av_remind_later, av_drag_away, av_offer_nudge, av_bar_click, av_dial_nudge, av_dial_again, av_engaged, av_halfway, av_slipping, av_wrong_way, av_done
- Character select: character_confirm_default, character_confirm_random, character_destroyed, character_rushed
- Login: password_intro, mic_close_refused
- Memo: memo_cc40, memo_eepy, memo_honest, memo_reply_all, memo_close_refused
- Wires: wires_crossed, wires_straight_first, wires_finally
- Screwdriver: screwdriver_wrong_way
- Valve: valve_reverse_thread, valve_righty_early, valve_closing, valve_leak
- Keypad / kaleidoscope: keypad_no_password, keypad_old_password, keypad_twist_me, keypad_wrong_1, keypad_wrong_2, scope_pickup, scope_open, scope_almost
- Candle: candle_match_fizzle
- Story: lights_out_3, server_room_still_empty, computer_no_power, switch_locked, switch_minigame, controls_shift_w
- Chairs: chair_push_2
- Locked objects: locked_1, locked_2, locked_3
- Off path: off_path_1..4
- Ending: ending_lights_back, ending_glasses_nudge_1, ending_glasses_nudge_2, ending_glasses_on, credits_end
- Misc: placeholder_minigame
