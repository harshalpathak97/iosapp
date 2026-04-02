import SwiftUI

struct QRScannerView: UIViewControllerRepresentable {
    @Binding var scannedCode: String?
    @Binding var isScanning: Bool

    class Coordinator: NSObject, QRScannerDelegate {
        var parent: QRScannerView
        var wasScanning: Bool = true

        init(_ parent: QRScannerView) {
            self.parent = parent
        }

        func didScanQRCode(_ code: String) {
            parent.scannedCode = code
            parent.isScanning = false
        }

        func didFailWithError(_ error: Error) {
            print("QR Scanner error: \(error.localizedDescription)")
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> QRScannerViewController {
        let controller = QRScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {
        let wasScanning = context.coordinator.wasScanning
        if isScanning && !wasScanning {
            uiViewController.resetScanner()
            uiViewController.startScanning()
        } else if !isScanning && wasScanning {
            uiViewController.stopScanning()
        }
        context.coordinator.wasScanning = isScanning
    }
}
