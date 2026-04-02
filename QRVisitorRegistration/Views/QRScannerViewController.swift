import UIKit
import AVFoundation

protocol QRScannerDelegate: AnyObject {
    func didScanQRCode(_ code: String)
    func didFailWithError(_ error: Error)
}

class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    weak var delegate: QRScannerDelegate?

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var isProcessing = false

    // Visual overlay elements
    private let scanFrameView = UIView()
    private let instructionLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        checkCameraPermissionAndSetup()
        setupOverlay()
    }

    private func checkCameraPermissionAndSetup() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupCamera()
                        self?.startScanning()
                    } else {
                        self?.showPermissionDeniedAlert()
                    }
                }
            }
        case .denied, .restricted:
            showPermissionDeniedAlert()
        @unknown default:
            showPermissionDeniedAlert()
        }
    }

    private func showPermissionDeniedAlert() {
        let label = UILabel()
        label.text = "Camera access is required.\nGo to Settings > Privacy > Camera\nto enable access for this app."
        label.textColor = .white
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 40),
            label.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -40),
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
        updateScanFrame()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startScanning()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopScanning()
    }

    private func setupCamera() {
        let session = AVCaptureSession()
        session.sessionPreset = .high

        guard let videoCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            showNoCameraAlert()
            return
        }

        guard let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else {
            return
        }

        if session.canAddInput(videoInput) {
            session.addInput(videoInput)
        }

        let metadataOutput = AVCaptureMetadataOutput()
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        self.captureSession = session
        self.previewLayer = previewLayer
    }

    private func setupOverlay() {
        // Semi-transparent scan frame
        scanFrameView.layer.borderColor = UIColor.systemBlue.cgColor
        scanFrameView.layer.borderWidth = 3
        scanFrameView.layer.cornerRadius = 16
        scanFrameView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.05)
        scanFrameView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scanFrameView)

        // Instruction label
        instructionLabel.text = "Point camera at a LinkedIn QR code"
        instructionLabel.textColor = .white
        instructionLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        instructionLabel.textAlignment = .center
        instructionLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        instructionLabel.layer.cornerRadius = 12
        instructionLabel.clipsToBounds = true
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(instructionLabel)

        NSLayoutConstraint.activate([
            scanFrameView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scanFrameView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            scanFrameView.widthAnchor.constraint(equalToConstant: 300),
            scanFrameView.heightAnchor.constraint(equalToConstant: 300),

            instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            instructionLabel.topAnchor.constraint(equalTo: scanFrameView.bottomAnchor, constant: 30),
            instructionLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 300),
            instructionLabel.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    private func updateScanFrame() {
        view.bringSubviewToFront(scanFrameView)
        view.bringSubviewToFront(instructionLabel)
    }

    func startScanning() {
        isProcessing = false
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }

    func stopScanning() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.stopRunning()
        }
    }

    func resetScanner() {
        isProcessing = false
        scanFrameView.layer.borderColor = UIColor.systemBlue.cgColor
        instructionLabel.text = "Point camera at a LinkedIn QR code"
    }

    private func showNoCameraAlert() {
        let label = UILabel()
        label.text = "No camera available.\nPlease run on a physical iPad."
        label.textColor = .white
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    // MARK: - AVCaptureMetadataOutputObjectsDelegate

    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        guard !isProcessing else { return }

        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              metadataObject.type == .qr,
              let scannedValue = metadataObject.stringValue else {
            return
        }

        // Check if it looks like a LinkedIn URL
        let lowered = scannedValue.lowercased()
        guard lowered.contains("linkedin.com") else {
            instructionLabel.text = "Not a LinkedIn QR code. Try again."
            scanFrameView.layer.borderColor = UIColor.systemOrange.cgColor
            return
        }

        isProcessing = true
        scanFrameView.layer.borderColor = UIColor.systemGreen.cgColor
        instructionLabel.text = "QR Code detected!"

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        delegate?.didScanQRCode(scannedValue)
    }
}
