/// `image/jpeg` → "JPEG", `image/svg+xml` → "SVG", `application/pdf` → "PDF".
String formatImageType(String mimeType) {
  final subtype = mimeType.split('/').last.split('+').first.trim();
  return subtype.isEmpty ? mimeType : subtype.toUpperCase();
}
