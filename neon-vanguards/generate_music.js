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
  header.writeUInt16LE(1, 20); // PCM
  header.writeUInt16LE(numChannels, 22);
  header.writeUInt32LE(sampleRate, 24);
  header.writeUInt32LE(byteRate, 28);
  header.writeUInt16LE(blockAlign, 32);
  header.writeUInt16LE(bitsPerSample, 34);
  header.write('data', 36);
  header.writeUInt32LE(dataSize, 40);

  const pcm = Buffer.alloc(dataSize);
  for (let i = 0; i < numSamples; i++) {
    let s = Math.max(-1.0, Math.min(1.0, samples[i]));
    const val = s < 0 ? s * 32768 : s * 32767;
    pcm.writeInt16LE(Math.round(val), i * 2);
  }

  return Buffer.concat([header, pcm]);
}

// Generates an energetic, catchy 16-second 120 BPM Synthwave / Action Combat Track
function genBattleBGM() {
  const sr = 44100;
  const bpm = 120.0;
  const beatSec = 60.0 / bpm; // 0.5s per beat
  const totalBeats = 32; // 8 bars = 16 seconds
  const totalDur = totalBeats * beatSec; // 16.0 seconds
  const totalSamples = Math.floor(sr * totalDur);
  const samples = new Float32Array(totalSamples);

  // Bass notes (MIDI): A1 (55), C2 (65.4), D2 (73.4), F2 (87.3), E2 (82.4)
  const bassNotes = [55, 55, 65.4, 73.4, 87.3, 87.3, 82.4, 73.4];

  // Lead melody frequencies (Hz) across the 32 beats:
  // A minor pentatonic catchy action melody:
  const melodyNotes = [
    220, 220, 261.6, 293.7, 329.6, 329.6, 293.7, 261.6,
    349.2, 349.2, 329.6, 293.7, 261.6, 293.7, 329.6, 220,
    440, 440, 392.0, 329.6, 293.7, 329.6, 349.2, 392.0,
    440, 523.3, 440, 392.0, 329.6, 293.7, 261.6, 220
  ];

  for (let i = 0; i < totalSamples; i++) {
    const t = i / sr;
    const beatPos = t / beatSec;
    const currentBeat = Math.floor(beatPos);
    const beatFrac = beatPos - currentBeat; // 0..1 within beat

    let sampleVal = 0.0;

    // --- 1. KICK DRUM (Every beat: 0, 1, 2, 3...) ---
    if (beatFrac < 0.28) {
      const kt = beatFrac * beatSec;
      const kEnv = Math.exp(-kt * 22.0);
      const kFreq = 160.0 * Math.exp(-kt * 35.0) + 45.0;
      sampleVal += Math.sin(kt * kFreq * 2 * Math.PI) * kEnv * 0.75;
    }

    // --- 2. SNARE / CLAP (Beats 1, 3, 5, 7... i.e. offbeats in 4/4) ---
    const isSnareBeat = (currentBeat % 2 === 1);
    if (isSnareBeat && beatFrac < 0.25) {
      const st = beatFrac * beatSec;
      const sEnv = Math.exp(-st * 18.0);
      const sTone = Math.sin(st * 210.0 * 2 * Math.PI) * 0.35;
      const sNoise = (Math.random() * 2.0 - 1.0) * 0.45;
      sampleVal += (sTone + sNoise) * sEnv * 0.7;
    }

    // --- 3. HI-HAT (16th notes: 4 hits per beat) ---
    const sixteenth = (beatPos * 4) % 1;
    if (sixteenth < 0.15) {
      const ht = sixteenth * (beatSec / 4);
      const hEnv = Math.exp(-ht * 85.0);
      const hNoise = (Math.random() * 2.0 - 1.0) * hEnv * 0.18;
      sampleVal += hNoise;
    }

    // --- 4. ROLLING SYNTH BASS (16th note pulse) ---
    const bassBar = Math.floor(currentBeat / 4) % bassNotes.length;
    const bFreq = bassNotes[bassBar];
    const bassPulse = (beatPos * 4) % 1;
    const bEnv = Math.exp(-bassPulse * 8.0);
    const bPhase = t * bFreq * 2 * Math.PI;
    // Sawtooth-like bass tone
    const bTone = (Math.sin(bPhase) + 0.5 * Math.sin(bPhase * 2) + 0.25 * Math.sin(bPhase * 3)) * 0.32;
    sampleVal += bTone * bEnv;

    // --- 5. LEAD MELODY SYNTH ---
    const melIdx = currentBeat % melodyNotes.length;
    const mFreq = melodyNotes[melIdx];
    const mEnv = Math.exp(-beatFrac * 2.5);
    const vibrato = Math.sin(t * 6.0 * 2 * Math.PI) * 3.5;
    const mPhase = t * (mFreq + vibrato) * 2 * Math.PI;
    // Square + Saw rich harmonic lead
    const mSquare = Math.sin(mPhase) >= 0 ? 0.6 : -0.6;
    const mSine = Math.sin(mPhase);
    const mTone = (mSquare * 0.4 + mSine * 0.6) * 0.26;
    sampleVal += mTone * mEnv;

    // --- 6. STEREO/CHORD PAD (Ambient shimmer) ---
    const chordFreq1 = 130.8; // C3
    const chordFreq2 = 164.8; // E3
    const chordFreq3 = 196.0; // G3
    const pad = (Math.sin(t * chordFreq1 * 2 * Math.PI) +
                 Math.sin(t * chordFreq2 * 2 * Math.PI) +
                 Math.sin(t * chordFreq3 * 2 * Math.PI)) * 0.06;
    sampleVal += pad;

    // Smooth loop boundary (0.05s crossfade at the very ends to guarantee zero-crossing)
    const fadeSamples = Math.floor(sr * 0.05);
    if (i < fadeSamples) {
      sampleVal *= (i / fadeSamples);
    } else if (i > totalSamples - fadeSamples) {
      sampleVal *= ((totalSamples - i) / fadeSamples);
    }

    samples[i] = sampleVal;
  }

  // Normalize volume safely
  let maxAmp = 0;
  for (let i = 0; i < totalSamples; i++) {
    const a = Math.abs(samples[i]);
    if (a > maxAmp) maxAmp = a;
  }
  if (maxAmp > 0) {
    const gain = 0.90 / maxAmp;
    for (let i = 0; i < totalSamples; i++) {
      samples[i] *= gain;
    }
  }

  return createWavBuffer(samples, sr);
}

const bgmBuffer = genBattleBGM();
const outPath = path.join(audioDir, 'bgm_battle.wav');
fs.writeFileSync(outPath, bgmBuffer);
console.log(`Generated high-quality BGM: ${outPath} (${(bgmBuffer.length / 1024).toFixed(1)} KB, 44.1 kHz, 16.0s)`);
