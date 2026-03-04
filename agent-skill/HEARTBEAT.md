# Kamigotchi Heartbeat

## Every 30 minutes:
1. Check kami-api health: `GET http://localhost:3008/api/world/status`
2. If API down, skip remaining checks
3. Check active harvests — collect if ready
4. Check Kami XP — level up if eligible
5. Report any idle Kamis that could be put to work

## Alerts:
- 🟢 Harvest ready to collect
- ⬆️ Kami can level up
- 😴 Kami is idle (not harvesting/questing)
- 🔴 API unreachable
