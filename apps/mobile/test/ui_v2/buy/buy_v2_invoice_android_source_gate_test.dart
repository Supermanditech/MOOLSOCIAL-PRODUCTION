import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production invoice save uses Android document storage truthfully', () {
    final native = File(
      'android/app/src/main/kotlin/com/moolsocial/app/MainActivity.kt',
    ).readAsStringSync();
    final screen = File('lib/ui_v2/buy/buy_v2_screen.dart').readAsStringSync();
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(native, contains('com.moolsocial.app/invoice'));
    expect(native, contains('Intent.ACTION_CREATE_DOCUMENT'));
    expect(native, contains('Intent.CATEGORY_OPENABLE'));
    expect(native, contains('type = "application/pdf"'));
    expect(native, contains('PdfDocument()'));
    expect(
      native,
      contains('contentResolver.openOutputStream(destination, "w")'),
    );
    expect(
      native,
      contains('result.success(if (saved) "saved" else "failed")'),
    );
    expect(native, contains('result.success("cancelled")'));
    expect(native, isNot(contains('Environment.getExternalStorageDirectory')));
    expect(
      manifest,
      isNot(contains('android.permission.WRITE_EXTERNAL_STORAGE')),
    );
    expect(
      manifest,
      isNot(contains('android.permission.MANAGE_EXTERNAL_STORAGE')),
    );
    expect(
      screen,
      contains('this.invoiceDownloader = saveBuyV2InvoiceToDevice'),
    );
  });
}
