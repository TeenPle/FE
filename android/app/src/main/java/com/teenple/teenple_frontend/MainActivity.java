package com.teenple.teenple_frontend;

import android.app.Activity;
import android.content.ContentResolver;
import android.content.ContentValues;
import android.content.Intent;
import android.database.Cursor;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.provider.MediaStore;
import android.webkit.MimeTypeMap;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.ByteArrayOutputStream;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "teenple/media";
    private static final int REQUEST_PICK_IMAGE = 4100;

    private MethodChannel.Result pendingPickResult;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(
                flutterEngine.getDartExecutor().getBinaryMessenger(),
                CHANNEL
        ).setMethodCallHandler(this::handleMediaCall);
    }

    private void handleMediaCall(MethodCall call, MethodChannel.Result result) {
        if ("pickImage".equals(call.method)) {
            pickImage(result);
            return;
        }
        if ("saveImageToGallery".equals(call.method)) {
            saveImageToGallery(call, result);
            return;
        }
        result.notImplemented();
    }

    private void pickImage(MethodChannel.Result result) {
        if (pendingPickResult != null) {
            result.error("PICK_IN_PROGRESS", "Image picker is already open.", null);
            return;
        }

        pendingPickResult = result;
        Intent intent = new Intent(Intent.ACTION_PICK, MediaStore.Images.Media.EXTERNAL_CONTENT_URI);
        intent.setType("image/*");
        try {
            startActivityForResult(intent, REQUEST_PICK_IMAGE);
        } catch (Exception e) {
            pendingPickResult = null;
            result.error("PICK_FAILED", e.getMessage(), null);
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode != REQUEST_PICK_IMAGE) return;

        MethodChannel.Result result = pendingPickResult;
        pendingPickResult = null;
        if (result == null) return;

        if (resultCode != Activity.RESULT_OK || data == null || data.getData() == null) {
            result.success(null);
            return;
        }

        try {
            Uri uri = data.getData();
            String mimeType = getContentResolver().getType(uri);
            String name = resolveDisplayName(uri, mimeType);
            PickedImage picked = copyUriToCache(uri, name);

            Map<String, Object> payload = new HashMap<>();
            payload.put("path", picked.file.getAbsolutePath());
            payload.put("name", name);
            payload.put("mimeType", mimeType == null ? "image/jpeg" : mimeType);
            payload.put("bytes", picked.bytes);
            result.success(payload);
        } catch (Exception e) {
            result.error("PICK_FAILED", e.getMessage(), null);
        }
    }

    private PickedImage copyUriToCache(Uri uri, String name) throws Exception {
        File dir = new File(getCacheDir(), "picked_images");
        if (!dir.exists() && !dir.mkdirs()) {
            throw new IllegalStateException("Cannot create cache directory.");
        }

        File file = new File(dir, System.currentTimeMillis() + "_" + sanitizeName(name));
        ByteArrayOutputStream memory = new ByteArrayOutputStream();
        try (InputStream input = getContentResolver().openInputStream(uri);
             OutputStream output = new FileOutputStream(file)) {
            if (input == null) throw new IllegalStateException("Cannot open selected image.");
            byte[] buffer = new byte[8192];
            int read;
            while ((read = input.read(buffer)) != -1) {
                output.write(buffer, 0, read);
                memory.write(buffer, 0, read);
            }
        }
        return new PickedImage(file, memory.toByteArray());
    }

    private String resolveDisplayName(Uri uri, String mimeType) {
        String name = null;
        try (Cursor cursor = getContentResolver().query(
                uri,
                new String[]{MediaStore.Images.Media.DISPLAY_NAME},
                null,
                null,
                null
        )) {
            if (cursor != null && cursor.moveToFirst()) {
                int index = cursor.getColumnIndex(MediaStore.Images.Media.DISPLAY_NAME);
                if (index >= 0) name = cursor.getString(index);
            }
        } catch (Exception ignored) {
        }

        if (name == null || name.trim().isEmpty()) {
            String ext = MimeTypeMap.getSingleton().getExtensionFromMimeType(mimeType);
            if (ext == null || ext.trim().isEmpty()) ext = "jpg";
            name = "chat-image." + ext.toLowerCase(Locale.ROOT);
        }
        return name;
    }

    private void saveImageToGallery(MethodCall call, MethodChannel.Result result) {
        byte[] bytes = call.argument("bytes");
        String name = call.argument("name");
        String mimeType = call.argument("mimeType");
        if (bytes == null || bytes.length == 0) {
            result.error("SAVE_FAILED", "Image bytes are empty.", null);
            return;
        }
        if (name == null || name.trim().isEmpty()) {
            name = "teenple_" + System.currentTimeMillis() + ".jpg";
        }
        if (mimeType == null || mimeType.trim().isEmpty()) {
            mimeType = name.toLowerCase(Locale.ROOT).endsWith(".png") ? "image/png" : "image/jpeg";
        }

        ContentResolver resolver = getContentResolver();
        ContentValues values = new ContentValues();
        values.put(MediaStore.Images.Media.DISPLAY_NAME, sanitizeName(name));
        values.put(MediaStore.Images.Media.MIME_TYPE, mimeType);

        Uri collection;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            collection = MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY);
            values.put(MediaStore.Images.Media.RELATIVE_PATH, Environment.DIRECTORY_PICTURES + "/TeenPle");
            values.put(MediaStore.Images.Media.IS_PENDING, 1);
        } else {
            collection = MediaStore.Images.Media.EXTERNAL_CONTENT_URI;
        }

        Uri item = null;
        try {
            item = resolver.insert(collection, values);
            if (item == null) throw new IllegalStateException("Cannot create gallery item.");

            try (OutputStream output = resolver.openOutputStream(item)) {
                if (output == null) throw new IllegalStateException("Cannot open gallery item.");
                output.write(bytes);
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                values.clear();
                values.put(MediaStore.Images.Media.IS_PENDING, 0);
                resolver.update(item, values, null, null);
            }
            result.success(true);
        } catch (Exception e) {
            if (item != null) resolver.delete(item, null, null);
            result.error("SAVE_FAILED", e.getMessage(), null);
        }
    }

    private String sanitizeName(String name) {
        return name.replaceAll("[\\\\/:*?\"<>|]", "_");
    }

    private static class PickedImage {
        final File file;
        final byte[] bytes;

        PickedImage(File file, byte[] bytes) {
            this.file = file;
            this.bytes = bytes;
        }
    }
}
