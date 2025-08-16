import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme.dart';
import 'chat_screen.dart';

class QRScannerScreen extends StatefulWidget {
  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  String scannedData = '';
  bool isScanned = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    if (!isScanned && barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      setState(() {
        scannedData = barcodes.first.rawValue!;
        isScanned = true;
      });
      cameraController.stop();
      showConfirmationDialog();
    }
  }

  void showConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'QR Code Scanned',
            style: TextStyle(color: AppTheme.primaryPurple),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.qr_code_2, size: 48, color: AppTheme.primaryPurple),
              SizedBox(height: 16),
              Text(
                'Session ID:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accentPurple,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  scannedData,
                  style: TextStyle(fontFamily: 'monospace', fontSize: 14),
                ),
              ),
              SizedBox(height: 16),
              Text('Do you want to start chatting?'),
              SizedBox(height: 8),
              Text(
                'After the chat, you can choose to save it to history.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  isScanned = false;
                });
                cameraController.start();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                startChat();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
              ),
              child: Text('Start Chat'),
            ),
          ],
        );
      },
    );
  }

  void startChat() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(sessionId: scannedData, isHost: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan QR Code'),
        backgroundColor: AppTheme.primaryPurple,
        actions: [
          IconButton(
            onPressed: () {
              cameraController.toggleTorch();
            },
            icon: ValueListenableBuilder(
              valueListenable: cameraController.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                }
              },
            ),
          ),
          IconButton(
            onPressed: () {
              cameraController.switchCamera();
            },
            icon: ValueListenableBuilder(
              valueListenable: cameraController.cameraFacingState,
              builder: (context, state, child) {
                switch (state) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear);
                }
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                MobileScanner(controller: cameraController, onDetect: onDetect),
                // Custom overlay
                Container(
                  decoration: ShapeDecoration(
                    shape: QrScannerOverlayShape(
                      borderColor: AppTheme.primaryPurple,
                      borderRadius: 10,
                      borderLength: 30,
                      borderWidth: 10,
                      cutOutSize: 250,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    size: 48,
                    color: AppTheme.primaryPurple,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Point your camera at a QR code',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.primaryPurple,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Make sure the QR code is clearly visible',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom overlay shape for QR scanner
class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path _getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top + borderRadius)
        ..quadraticBezierTo(
          rect.left,
          rect.top,
          rect.left + borderRadius,
          rect.top,
        )
        ..lineTo(rect.right, rect.top);
    }

    return _getLeftTopPath(rect)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final borderWidthSize = width / 2;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final _borderLength = borderLength > cutOutSize / 2 + borderWidth * 2
        ? borderWidthSize / 2
        : borderLength;
    final _cutOutSize = cutOutSize < width ? cutOutSize : width - borderOffset;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final boxPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    final cutOutRect = Rect.fromLTWH(
      rect.left + width / 2 - _cutOutSize / 2 + borderOffset,
      rect.top + height / 2 - _cutOutSize / 2 + borderOffset,
      _cutOutSize - borderOffset * 2,
      _cutOutSize - borderOffset * 2,
    );

    // Draw background
    canvas.saveLayer(rect, backgroundPaint);
    canvas.drawRect(rect, backgroundPaint);

    // Draw cut out
    canvas.drawRRect(
      RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)),
      boxPaint,
    );

    canvas.restore();

    // Draw border
    canvas.drawRRect(
      RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)),
      borderPaint,
    );

    // Draw corner lines
    final lineLength = _borderLength;
    final lineWidth = borderWidth;
    final cornerPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth
      ..strokeCap = StrokeCap.round;

    // Top left corner
    canvas.drawLine(
      Offset(cutOutRect.left - lineWidth / 2, cutOutRect.top + lineLength),
      Offset(cutOutRect.left - lineWidth / 2, cutOutRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cutOutRect.left, cutOutRect.top - lineWidth / 2),
      Offset(cutOutRect.left + lineLength, cutOutRect.top - lineWidth / 2),
      cornerPaint,
    );

    // Top right corner
    canvas.drawLine(
      Offset(cutOutRect.right + lineWidth / 2, cutOutRect.top + lineLength),
      Offset(cutOutRect.right + lineWidth / 2, cutOutRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cutOutRect.right, cutOutRect.top - lineWidth / 2),
      Offset(cutOutRect.right - lineLength, cutOutRect.top - lineWidth / 2),
      cornerPaint,
    );

    // Bottom left corner
    canvas.drawLine(
      Offset(cutOutRect.left - lineWidth / 2, cutOutRect.bottom - lineLength),
      Offset(cutOutRect.left - lineWidth / 2, cutOutRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cutOutRect.left, cutOutRect.bottom + lineWidth / 2),
      Offset(cutOutRect.left + lineLength, cutOutRect.bottom + lineWidth / 2),
      cornerPaint,
    );

    // Bottom right corner
    canvas.drawLine(
      Offset(cutOutRect.right + lineWidth / 2, cutOutRect.bottom - lineLength),
      Offset(cutOutRect.right + lineWidth / 2, cutOutRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cutOutRect.right, cutOutRect.bottom + lineWidth / 2),
      Offset(cutOutRect.right - lineLength, cutOutRect.bottom + lineWidth / 2),
      cornerPaint,
    );
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
    );
  }
}
