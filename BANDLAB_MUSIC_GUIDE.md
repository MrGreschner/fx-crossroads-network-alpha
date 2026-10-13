# BandLab, sound effects and Music Studio

## Student workflow

Use BandLab in a web browser. In its Studio, choose **Project → Download → Mixdown As → WAV**. WAV is the simplest route into FX Crossroads. MP3 is also supported; M4A is not. Renaming an M4A file to WAV does not convert it.

### A sound for a custom ability

1. Make an effect lasting at most **four seconds**. Trim silence and add a brief fade at each end to avoid clicks.
2. Download the effect as WAV. The game accepts imports up to 2 MB and automatically prepares WAV audio as a small mono recording; the portable result must fit in 128 KB.
3. Open **Crossroads Studio → Ability Lab → Sound → Upload**.
4. Listen, adjust volume/pitch and test the ability. The sound travels in the ability and hero files and in the player ZIP.

### A realm soundtrack

1. Make a recording lasting up to **three minutes**. Short recordings repeat, so listen carefully to the transition at the end.
2. Open **Crossroads Studio → Music Studio**, or the Music Studio button in Media controls.
3. Upload WAV/MP3. WAV input can be up to 32 MB; the game prepares it as 22.05 kHz mono. This prototype copy is smaller than the original production master. Keep the original BandLab project.
4. Enter a title, composer and a production note. Adjust the music level; the game's Sound mute also applies.
5. Select a realm/location and press **Assign to selected location**. **Play realm** launches a solo test with the selected realm soundtrack. Other game styles use their usual entrances.
6. Save and return. Download the player ZIP before leaving a shared computer.

The collection holds **four tracks, with 8 MB of prepared audio combined**. Remove older prototypes or use MP3 when a collection is too large. Location assignments are independent of the hero being played. Uploading audio never changes an official hero's combat abilities.

### Submissions and feedback

**Download submission** produces a portable `.music.json` file containing audio, title, composer and notes. Another student or teacher can import that file in Music Studio. The player ZIP also contains a `music/` folder with recordings and settings. Share a submission rather than the entire account when only sharing music.

Suggested reflection: identify your intended audience, mood and instrumentation; explain how the soundtrack supports the level; test whether combat cues remain audible; describe one change made after peer feedback. Capture gameplay in Media mode and record video with OBS.

### Multiplayer

The host's assigned prototype soundtrack is offered to guests through the existing reliable peer channel. Audio travels in paced chunks, outside state snapshots and outside the room service. Guests may hear the bundled soundtrack or silence while a prototype transfers; large WAV recordings and larger parties take longer. Use compact MP3 for quicker multiplayer auditions. Once received, the guest starts near the host's playback position. Guest recordings remain temporary and do not enter the guest's account.

Host and guests can still mute all sound locally. A guest's personal realm assignment does not override the host's selection. Music does not provide progress or unlock rewards. Game Dev edits are temporary and cannot be exported as account submissions.

## Make a selected submission official

1. Collect and listen to the student's `.music.json` submission. Retain its composer credit and original BandLab project/export for production.
2. Put the selected portable file in `content/music/`, for example `content/music/grove.music.json`.
3. Edit `content/music/official.json`:

```json
{
  "realm:grove": {
    "path": "res://content/music/grove.music.json",
    "title": "Whispering Grove",
    "author": "Student composer",
    "volume_db": -18
  }
}
```

4. Test with no personal prototype assigned to that location, or turn off prototype soundtracks in Music Studio. Personal assignments take priority during auditions.
5. Re-export Web and Windows. Both export presets already include the music JSON files. No Render change is needed.

Use `realm:<region ID>` for realms, and `mode:town`, `mode:training`, `mode:defense`, `mode:descent`, `mode:arena` or `mode:battlegrounds` for other destinations. Region IDs are the filenames in `content/regions/` without `.json`.

## Media shortcut guide

The Media camera panel displays this guide when Media/Game Dev tools are available:

- **F8**: photograph after a three-second timer.
- **F9**: show/hide camera controls.
- **F10**: hide/restore HUD for OBS.

Buttons provide touch-friendly alternatives. Type `media` to Elder Ram for normal-account Media tools. Game Dev uses `gameDev` followed by `R4ms!` and receives the same camera tools.

BandLab documentation: https://help.bandlab.com/hc/en-us/articles/115002959774-Downloading-Mixdowns-and-Tracks and https://help.bandlab.com/hc/en-us/articles/360036010533-Supported-Import-and-Export-File-Formats
