# OpenCode AI Chat

Aplikasi chat AI Android dengan kumpulan model gratis via OpenRouter.

## Fitur
- Kumpulan model AI gratis langsung bisa dipilih
- Riwayat chat tersimpan
- UI mirip ChatGPT dengan dark mode
- Mendukung markdown
- API key disimpan lokal

## Cara Build APK

### Persiapan
1. Install Flutter SDK
2. Buka project ini
3. Jalankan `flutter pub get`

### Build APK
```bash
flutter build apk --release
```

APK akan ada di: `build/app/outputs/flutter-apk/app-release.apk`

## Cara Pakai
1. Buka aplikasi
2. Masuk ke Pengaturan (ikon gear)
3. Dapatkan API key gratis di [openrouter.ai/keys](https://www.openrouter.ai/keys)
4. Masukkan API key dan simpan
5. Pilih model gratis yang pengen dipake
6. Mulai chat!

## Model Gratis yang Tersedia
- Google Gemma 2 9B/27B
- Meta Llama 3.1 8B, 3.2 3B
- Mistral 7B
- Microsoft Phi-3 Mini
- HuggingFace Zephyr 7B
- Qwen 2 7B
- DeepSeek Chat V3

Dibuat dengan ❤️ untuk OpenCode community
