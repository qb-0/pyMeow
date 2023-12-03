import
  nimpy, tables,
  nimraylib_now as rl

pyExportModule("pyMeow")

type
  SoundObj = object
    id: int
    sound: Sound

var
  curSoundId = -1
  soundTable: Table[int, SoundObj]

proc soundInit {.exportpy: "sound_init".} =
  rl.initAudioDevice()

proc soundDeinit {.exportpy: "sound_deinit".} =
  rl.closeAudioDevice()

proc loadSound(fileName: string): int {.exportpy: "load_sound".} =
  inc curSoundId
  soundTable[curSoundId] = SoundObj(id: curSoundId, sound: rl.loadSound(fileName))
  result = curSoundId

proc unloadSound(soundId: int) {.exportpy: "unload_sound".} =
  rl.unloadSound(soundTable[soundId].sound)
  soundTable.del(soundId)

proc playSound(soundId: int) {.exportpy: "play_sound".} =
  rl.playSound(soundTable[soundId].sound)

proc pauseSound(soundId: int) {.exportpy: "pause_sound".} =
  rl.pauseSound(soundTable[soundId].sound)

proc resumeSound(soundId: int) {.exportpy: "resume_sound".} =
  rl.resumeSound(soundTable[soundId].sound)

proc stopSound(soundId: int) {.exportpy: "stop_sound".} =
  rl.stopSound(soundTable[soundId].sound)

proc playMultiSound(soundId: int) {.exportpy: "play_multisound".} =
  rl.playSoundMulti(soundTable[soundId].sound)

proc stopMultiSound() {.exportpy: "stop_multisound".} =
  rl.stopSoundMulti()

proc setSoundVolume(soundId: int, volume: int) {.exportpy: "set_sound_volume".} =
  rl.setSoundVolume(soundTable[soundId].sound, volume.float / 100.0)

proc isSoundPlaying(soundId: int): bool {.exportpy: "is_sound_playing".} =
  rl.isSoundPlaying(soundTable[soundId].sound)
