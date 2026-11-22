const fs = require('fs');
const path = require('path');

const audioDir = 'C:/Users/User/.gemini/antigravity/scratch/neon-vanguards/assets/audio';
if (!fs.existsSync(audioDir)) {
  fs.mkdirSync(audioDir, { recursive: true });
}

function createWavBuffer(samples, sampleRate = 44100) {
  const numSamples = samples.length;
  const bitsPerSample = 16;
  const numChannels = 1;
  const byteRate = sampleRate * numChannels * (bitsPerSample / 8);
  const blockAlign = numChannels * (bitsPerSample / 8);
  const dataSize = numSamples * (bitsPerSample / 8);
  const header = Buffer.alloc(44);

  header.write('RIFF', 0);
  header.writeUInt32LE(36 + dataSize, 4);
  header.write('WAVE', 8);
  header.write('fmt ', 12);
  header.writeUInt32LE(16, 16);
  header.writeUInt16LE(1, 20); // PCM format
  header.writeUInt16LE(numChannels, 22);
  header.writeUInt32LE(sampleRate, 24);
  header.writeUInt32LE(byteRate, 28);
  header.writeUInt16LE(blockAlign, 32);
  header.writeUInt16LE(bitsPerSample, 34);
  header.write('data', 36);
  header.writeUInt32LE(dataSize, 40);

  const pcm = Buffer.alloc(dataSize);
  for (let i = 0; i < numSamples; i++) {
    // Soft limiter (tanh-like compression to prevent clipping)
    let s = samples[i];
    s = Math.tanh(s * 1.15) * 0.95;
    const val = s < 0 ? s * 32768 : s * 32767;
    pcm.writeInt16LE(Math.max(-32768, Math.min(32767, Math.round(val))), i * 2);
  }

  return Buffer.concat([header, pcm]);
}

// Lowpass filter utility (Simple single-pole RC filter)
class LowPassFilter {
  constructor(cutoff, sampleRate) {
    this.setCutoff(cutoff, sampleRate);
    this.last = 0;
  }
  setCutoff(cutoff, sampleRate) {
    const rc = 1.0 / (2.0 * Math.PI * cutoff);
    const dt = 1.0 / sampleRate;
    this.alpha = dt / (rc + dt);
  }
  process(x) {
    this.last += this.alpha * (x - this.last);
    return this.last;
  }
}

// Highpass filter utility
class HighPassFilter {
  constructor(cutoff, sampleRate) {
    const rc = 1.0 / (2.0 * Math.PI * cutoff);
    const dt = 1.0 / sampleRate;
    this.alpha = rc / (rc + dt);
    this.lastInput = 0;
    this.lastOutput = 0;
  }
  process(x) {
    this.lastOutput = this.alpha * (this.lastOutput + x - this.lastInput);
    this.lastInput = x;
    return this.lastOutput;
  }
}

// Generate a modern, tactical, high-energy military-cyber action theme
// Key: D minor (epic action key: Dm - Bb - F - C)
function generateModernCombatTheme() {
  const sr = 44100;
  const bpm = 124.0;
  const beatSec = 60.0 / bpm; // ~0.4838s
  const totalBeats = 64; // 16 bars total (~30.96s)
  const totalDur = totalBeats * beatSec;
  const totalSamples = Math.floor(sr * totalDur);

  const track = new Float32Array(totalSamples);
  const delayBuffer = new Float32Array(totalSamples);

  // Chord progression (4 beats per chord, cycles 4 times):
  // 1: D minor (D3: 146.83, F3: 174.61, A3: 220.00)
  // 2: Bb major (Bb2: 116.54, D3: 146.83, F3: 174.61)
  // 3: F major  (F2: 87.31, A2: 110.00, C3: 130.81)
  // 4: C major  (C3: 130.81, E3: 164.81, G3: 196.00)
  const chordRoots = [73.42, 58.27, 43.65, 65.41]; // D2, Bb1, F1, C2
  const chordTones = [
    [146.83, 174.61, 220.00, 261.63], // Dm7 (D3, F3, A3, C4)
    [116.54, 146.83, 174.61, 220.00], // Bbmaj7 (Bb2, D3, F3, A3)
    [174.61, 220.00, 261.63, 329.63], // Fadd9 (F3, A3, C4, E4)
    [130.81, 164.81, 196.00, 246.94]  // Cmaj7 (C3, E3, G3, B3)
  ];

  // Tactical Arpeggio pattern (16th notes: 16 notes per bar)
  // Note offsets in semitones from root
  const arpSemitones = [0, 12, 7, 12, 3, 12, 7, 12, 0, 12, 7, 12, 3, 12, 7, 10];

  // Epic combat lead melody (bars 9 to 16, i.e. beats 32 to 64)
  // Frequencies in Hz for each beat:
  const leadMelody = [
    // Bar 9 (Dm): D4, D4, F4, G4
    293.66, 293.66, 349.23, 392.00,
    // Bar 10 (Bb): A4, F4, D4, C4
    440.00, 349.23, 293.66, 261.63,
    // Bar 11 (F): F4, G4, A4, C5
    349.23, 392.00, 440.00, 523.25,
    // Bar 12 (C): A4, G4, F4, E4
    440.00, 392.00, 349.23, 329.63,
    // Bar 13 (Dm): D4, F4, A4, D5
    293.66, 349.23, 440.00, 587.33,
    // Bar 14 (Bb): C5, Bb4, A4, F4
    523.25, 466.16, 440.00, 349.23,
    // Bar 15 (F): G4, A4, C5, A4
    392.00, 440.00, 523.25, 440.00,
    // Bar 16 (C): G4, F4, E4, C4
    392.00, 349.23, 329.63, 261.63
  ];

  const bassLpf = new LowPassFilter(380, sr);
  const padLpf = new LowPassFilter(1600, sr);
  const arpLpf = new LowPassFilter(2400, sr);
  const snareHpf = new HighPassFilter(180, sr);
  const hatHpf = new HighPassFilter(3500, sr);

  for (let i = 0; i < totalSamples; i++) {
    const t = i / sr;
    const beatPos = t / beatSec;
    const currentBeat = Math.floor(beatPos);
    const beatFrac = beatPos - currentBeat; // 0..1 within beat
    const currentBar = Math.floor(currentBeat / 4);
    const chordIdx = currentBar % 4;

    let sDrum = 0.0;
    let sBass = 0.0;
    let sPad = 0.0;
    let sArp = 0.0;
    let sLead = 0.0;

    // ==========================================
    // 1. DRUMS (Modern Tactical Action Beat)
    // ==========================================
    // Kick drum pattern: standard driving syncopation (Beats 0, 1.75, 2.5)
    const barBeat = beatPos % 4;
    const isKick1 = beatFrac < 0.22 && (barBeat < 0.25 || (barBeat >= 2.5 && barBeat < 2.75) || (barBeat >= 1.75 && barBeat < 2.0));
    if (isKick1) {
      const kt = (barBeat % 1) * beatSec;
      const kEnv = Math.exp(-kt * 24.0);
      const kFreq = 140.0 * Math.exp(-kt * 38.0) + 48.0;
      sDrum += Math.sin(kt * kFreq * 2 * Math.PI) * kEnv * 0.85;
    }

    // Snare drum: Crisp snap on beats 1 and 3 (0-indexed: 2nd and 4th beat)
    const isSnare = (barBeat >= 1.0 && barBeat < 1.3) || (barBeat >= 3.0 && barBeat < 3.3);
    if (isSnare) {
      const st = (barBeat % 1) * beatSec;
      const sEnv = Math.exp(-st * 16.0);
      // Dual tone + snappy filtered noise
      const sTone = Math.sin(st * 190.0 * 2 * Math.PI) * 0.4;
      const sNoise = (Math.random() * 2.0 - 1.0) * 0.6;
      sDrum += snareHpf.process(sTone + sNoise) * sEnv * 0.75;
    }

    // Hi-Hats: 16th-note groove with velocity accents
    const sixteenth = (beatPos * 4) % 1;
    if (sixteenth < 0.12) {
      const ht = sixteenth * (beatSec / 4);
      const hEnv = Math.exp(-ht * 90.0);
      const accent = ((Math.floor(beatPos * 4) % 4) === 2) ? 1.0 : 0.6; // Offbeat accent
      const hNoise = (Math.random() * 2.0 - 1.0) * hEnv * accent * 0.22;
      sDrum += hatHpf.process(hNoise);
    }

    // Crash cymbal at the very beginning of the 16-bar phrase (beat 0)
    if (beatPos < 4.0) {
      const ct = beatPos * beatSec;
      const cEnv = Math.exp(-ct * 1.8);
      const cNoise = (Math.random() * 2.0 - 1.0) * cEnv * 0.25;
      sDrum += hatHpf.process(cNoise);
    }

    // ==========================================
    // 2. 808 SUB BASS (Deep, warm, rounded)
    // ==========================================
    const bRoot = chordRoots[chordIdx];
    // Rhythmic 8th-note pump:
    const eighth = (beatPos * 2) % 1;
    const bEnv = Math.exp(-eighth * 3.5);
    const bPhase1 = t * bRoot * 2 * Math.PI;
    const bPhase2 = t * (bRoot * 1.002) * 2 * Math.PI; // Gentle chorus detune
    // Warm, rounded saturation, strictly low-pass filtered
    const rawBass = (Math.sin(bPhase1) * 0.7 + Math.sin(bPhase2) * 0.3);
    sBass = bassLpf.process(rawBass) * bEnv * 0.65;

    // ==========================================
    // 3. WARM CINEMATIC PADS (Atmospheric swell)
    // ==========================================
    const currentChord = chordTones[chordIdx];
    let padSum = 0.0;
    for (let c = 0; c < currentChord.length; c++) {
      const f = currentChord[c];
      // Soft detuned stereo oscillator
      const p1 = Math.sin(t * f * 2 * Math.PI);
      const p2 = Math.sin(t * (f * 1.003) * 2 * Math.PI);
      padSum += (p1 + p2) * 0.25;
    }
    // Gentle breathing swell over each 4-beat bar
    const barFrac = (beatPos % 4) / 4.0;
    const padSwell = Math.sin(barFrac * Math.PI) * 0.7 + 0.3;
    sPad = padLpf.process(padSum) * padSwell * 0.22;

    // ==========================================
    // 4. TACTICAL 16th-NOTE ARPEGGIO PLUCK
    // ==========================================
    const arp16thIdx = Math.floor(beatPos * 4) % 16;
    const semi = arpSemitones[arp16thIdx];
    const arpFreq = bRoot * 2.0 * Math.pow(2.0, semi / 12.0); // 2 octaves above root
    const arpTime = (beatPos * 4) % 1;
    const arpEnv = Math.exp(-arpTime * 8.0); // Plucky decay
    const arpPhase = t * arpFreq * 2 * Math.PI;
    // Filtered pluck
    const rawArp = Math.sin(arpPhase) + 0.3 * Math.sin(arpPhase * 2);
    sArp = arpLpf.process(rawArp) * arpEnv * 0.24;

    // ==========================================
    // 5. COMBAT LEAD MELODY (Enters at bar 9 = beat 32)
    // ==========================================
    if (currentBeat >= 32 && currentBeat < 64) {
      const melIdx = currentBeat - 32;
      const mFreq = leadMelody[melIdx];
      const mEnv = Math.exp(-beatFrac * 2.2);
      // Subtle vibrato after 0.15s of the note
      const vibAmount = beatFrac > 0.15 ? Math.sin((beatFrac - 0.15) * 6.0 * 2 * Math.PI) * 2.5 : 0.0;
      const mPhase = t * (mFreq + vibAmount) * 2 * Math.PI;
      // Smooth warm saw/sine mix (not harsh square)
      const mTone = Math.sin(mPhase) * 0.65 + Math.sin(mPhase * 2) * 0.25 + Math.sin(mPhase * 3) * 0.1;
      sLead = mTone * mEnv * 0.35;
    }

    // ==========================================
    // MIXING & DELAY EFFECT (Ambient space)
    // ==========================================
    let dry = sDrum + sBass + sPad + sArp + sLead;

    // 3/16-beat tempo-synced delay line for lead & arp
    const delaySamples = Math.floor(sr * (beatSec * 0.75));
    if (i >= delaySamples) {
      dry += delayBuffer[i - delaySamples] * 0.25;
    }
    delayBuffer[i] = (sArp + sLead);

    // Smooth seamless zero-crossing loop fade (0.04s)
    const fadeSamples = Math.floor(sr * 0.04);
    if (i < fadeSamples) {
      dry *= (i / fadeSamples);
    } else if (i > totalSamples - fadeSamples) {
      dry *= ((totalSamples - i) / fadeSamples);
    }

    track[i] = dry;
  }

  return createWavBuffer(track, sr);
}

const wavBuffer = generateModernCombatTheme();
const dest = path.join(audioDir, 'bgm_battle.wav');
fs.writeFileSync(dest, wavBuffer);
console.log(`Generated upgraded modern combat BGM: ${dest} (${(wavBuffer.length / 1024 / 1024).toFixed(2)} MB, 124 BPM, 31.0s loop)`);
