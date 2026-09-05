export interface StepDuration {
  seconds: number
  label: string
}

// recipe steps are free text, so durations can only be found per language - the alternatives
// are ordered so that the longer unit names win over the ones they contain ("másodperc"/"perc")
const durationPatterns: Record<string, { regex: RegExp, unitToSeconds: (unit: string) => number }> = {
  en: {
    regex: /(\d+(?:[.,]\d+)?)(?:\s*(?:[-–—]|to|or)\s*\d+(?:[.,]\d+)?)?\s*(hours?|hrs?|minutes?|mins?|seconds?|secs?)\b/gi,
    unitToSeconds: (unit) => {
      if (unit.startsWith('h'))
        return 3600

      return unit.startsWith('m') ? 60 : 1
    },
  },
  hu: {
    regex: /(\d+(?:[.,]\d+)?)(?:\s*(?:[-–—]|vagy)\s*\d+(?:[.,]\d+)?)?\s*(másodperc\w*|perc\w*|ór[aá]\w*)/gi,
    unitToSeconds: (unit) => {
      if (unit.startsWith('ó'))
        return 3600

      return unit.startsWith('p') ? 60 : 1
    },
  },
}

// scanning is quadratic in the step length on digit heavy text, and no real cooking step is
// anywhere near this long - imported recipes can put anything in here, so it needs a bound
const maxParsedStepLength = 2000

// for a range ("simmer for 20-25 minutes") the lower bound is used, since a timer going off
// early can be extended, while one going off late has already burnt the food
export function parseStepDurations(step: string, locale: string): StepDuration[] {
  if (step.length > maxParsedStepLength)
    return []

  const pattern = durationPatterns[locale] || durationPatterns.en!
  const durations = new Map<number, StepDuration>()

  for (const match of step.matchAll(pattern.regex)) {
    const amount = Number.parseFloat(match[1]!.replace(',', '.'))
    if (!Number.isFinite(amount) || amount <= 0)
      continue

    const seconds = Math.round(amount * pattern.unitToSeconds(match[2]!.toLowerCase()))
    if (seconds < 1 || durations.has(seconds))
      continue

    durations.set(seconds, { seconds, label: match[0]!.trim() })
  }

  return [...durations.values()]
}

export function formatTimerValue(totalSeconds: number) {
  const seconds = Math.max(0, totalSeconds)
  const pad = (value: number) => value.toString().padStart(2, '0')

  const hours = Math.floor(seconds / 3600)
  const minutes = Math.floor((seconds % 3600) / 60)

  if (hours)
    return `${hours}:${pad(minutes)}:${pad(seconds % 60)}`

  return `${minutes}:${pad(seconds % 60)}`
}

let alarmContext: AudioContext | null = null

// browsers only let an AudioContext start from a user gesture, so this has to run on the tap
// that starts a timer - by the time the timer runs out there is no gesture left to use
export function primeCookAlarm() {
  try {
    alarmContext ||= new AudioContext()

    if (alarmContext.state === 'suspended')
      alarmContext.resume()
  }
  catch (error) {
    console.error('Could not prepare the timer alarm:', error)
  }
}

export function playCookAlarm() {
  navigator.vibrate?.([200, 100, 200, 100, 200])

  if (alarmContext?.state !== 'running')
    return

  for (let beep = 0; beep < 3; beep++) {
    const startAt = alarmContext.currentTime + beep * 0.4

    const oscillator = alarmContext.createOscillator()
    oscillator.frequency.value = 880

    const gain = alarmContext.createGain()
    gain.gain.setValueAtTime(0.0001, startAt)
    gain.gain.exponentialRampToValueAtTime(0.3, startAt + 0.02)
    gain.gain.exponentialRampToValueAtTime(0.0001, startAt + 0.25)

    oscillator.connect(gain).connect(alarmContext.destination)
    oscillator.start(startAt)
    oscillator.stop(startAt + 0.3)
  }
}
