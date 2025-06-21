# Making Turf Loss “Sting” – Emotional Design Notes

Goal:  heighten player attachment to their territory so that losing it feels visceral, sparking immediate desire to retaliate—*without* crossing into toxic design or real-world danger.

--------------------------------------------------
1. Leverage Loss Aversion (Kahneman & Tversky)
--------------------------------------------------
• **Visible Investment Meter** – Show how much cash and time you have sunk into each turf (progress bar, upgrade stars).  Bigger bars = bigger perceived loss.

• **Escalating Income Curve** – Early hours produce little, later hours ramp sharply.  The longer you hold, the more lucrative it becomes, so a late steal hurts.

• **‘Everything you didn’t collect’** – When vault cash is stolen, present the exact figure you FAILED to bank (e.g., “$4 230 snatched while you slept!”).

--------------------------------------------------
2. Sensory Punch
--------------------------------------------------
• **Haptics** – Strong double-buzz pattern on turf-loss push; unique from normal alerts.

• **Audio Sting** – 500 ms discordant ‘alarm’ wav in notification payload; triggers visceral reaction.

• **Color Flash** – Map briefly washes red, then fades back; hex cracks animation.

--------------------------------------------------
3. Social Ego Triggers
--------------------------------------------------
• **Public Feed** – “@Rival just jacked Central Park from @You” visible to nearby players.

• **Leaderboards Drop** – Immediate downward arrow shows rank lost; subtle shame driver.

• **Crest Defacement** – New owner’s emblem overlays yours with spray-paint animation; lingering vandalized version shown for 24 h even after you recapture.

--------------------------------------------------
4. Blocking Recovery Window
--------------------------------------------------
• **Shield Cool-down** – After losing, turf auto-locks for 10 min, preventing instant retake; forces you to *stew*.

• **Penalty Timer** – Your next attack on that turf costs 10 % extra weapons fee (salt in wound).

--------------------------------------------------
5. Narrative Copywriting
--------------------------------------------------
• Push Notification Examples:  
   – “🔴 They took your turf! Show them it was a mistake.”  
   – “💸 $1 780 gone. Are you going to let that slide?”

• In-app banner: “Central Park now flies Rival colors. Reclaim your honor.”

--------------------------------------------------
6. Ethical Safeguards
--------------------------------------------------
• No location addresses in public feed (use POI names only).  
• Mute / Do-Not-Disturb hours (late-night push optional).  
• ‘Angry’ copy stays PG-13; no personal insults or harassment.

--------------------------------------------------
7. Playtest Checklist
--------------------------------------------------
☐ Players report genuine irritation when turf lost.  
☐ Irritation converts to re-engagement, not uninstall.  
☐ No spike in support tickets for harassment.

--------------------------------------------------
Implementation Order (after Phase 4)
--------------------------------------------------
1. Loss notification payload (haptics + audio).  
2. On-loss UI animations & vault delta screen.  
3. Public feed + leaderboard delta.  
4. Cool-down & penalty economics.  
5. Crest defacement art.

Deliverables: copy strings, haptic pattern spec, SFX WAV, red-wash animation, defaced crest overlay.
