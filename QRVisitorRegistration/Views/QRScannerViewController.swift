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
        // Scan frame with rounded corners
        scanFrameView.layer.borderColor = UIColor.white.withAlphaComponent(0.6).cgColor
        scanFrameView.layer.borderWidth = 2
        scanFrameView.layer.cornerRadius = 24
        scanFrameView.backgroundColor = .clear
        scanFrameView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scanFrameView)

        // Corner accents (4 L-shaped marks in primary color)
        addCornerAccents()

        // Instruction label (pill-shaped, primary color background)
        instructionLabel.text = "Align a LinkedIn QR code within the frame"
        instructionLabel.textColor = .white
        instructionLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        instructionLabel.textAlignment = .center
        instructionLabel.backgroundColor = UIColor(red: 0.30, green: 0.45, blue: 0.95, alpha: 0.92)
        instructionLabel.layer.cornerRadius = 22
        instructionLabel.clipsToBounds = true
        instructionLabel.layer.shadowColor = UIColor.black.cgColor
        instructionLabel.layer.shadowOpacity = 0.3
        instructionLabel.layer.shadowOffset = CGSize(width: 0, height: 4)
        instructionLabel.layer.shadowRadius = 12
        instructionLabel.layer.masksToBounds = false
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(instructionLabel)

        NSLayoutConstraint.activate([
            scanFrameView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scanFrameView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            scanFrameView.widthAnchor.constraint(equalToConstant: 300),
            scanFrameView.heightAnchor.constraint(equalToConstant: 300),

            instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            instructionLabel.topAnchor.constraint(equalTo: scanFrameView.bottomAnchor, constant: 40),
            instructionLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 320),
            instructionLabel.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    private func addCornerAccents() {
        let accentColor = UIColor(red: 0.30, green: 0.45, blue: 0.95, alpha: 1.0)
        let length: CGFloat = 28
        let thickness: CGFloat = 4

        for corner in 0..<4 {
            let h = UIView()
            h.backgroundColor = accentColor
            h.layer.cornerRadius = thickness / 2
            h.translatesAutoresizingMaskIntoConstraints = false
            scanFrameView.addSubview(h)

            let v = UIView()
            v.backgroundColor = accentColor
            v.layer.cornerRadius = thickness / 2
            v.translatesAutoresizingMaskIntoConstraints = false
            scanFrameView.addSubview(v)

            switch corner {
            case 0: // top-left
                NSLayoutConstraint.activate([
                    h.topAnchor.constraint(equalTo: scanFrameView.topAnchor, constant: -2),
                    h.leadingAnchor.constraint(equalTo: scanFrameView.leadingAnchor, constant: -2),
                    h.widthAnchor.constraint(equalToConstant: length),
                    h.heightAnchor.constraint(equalToConstant: thickness),
                    v.topAnchor.constraint(equalTo: scanFrameView.topAnchor, constant: -2),
                    v.leadingAnchor.constraint(equalTo: scanFrameView.leadingAnchor, constant: -2),
                    v.widthAnchor.constraint(equalToConstant: thickness),
                    v.heightAnchor.constraint(equalToConstant: length),
                ])
            case 1: // top-right
                NSLayoutConstraint.activate([
                    h.topAnchor.constraint(equalTo: scanFrameView.topAnchor, constant: -2),
                    h.trailingAnchor.constraint(equalTo: scanFrameView.trailingAnchor, constant: 2),
                    h.widthAnchor.constraint(equalToConstant: length),
                    h.heightAnchor.constraint(equalToConstant: thickness),
                    v.topAnchor.constraint(equalTo: scanFrameView.topAnchor, constant: -2),
                    v.trailingAnchor.constraint(equalTo: scanFrameView.trailingAnchor, constant: 2),
                    v.widthAnchor.constraint(equalToConstant: thickness),
                    v.heightAnchor.constraint(equalToConstant: length),
                ])
            case 2: // bottom-left
                NSLayoutConstraint.activate([
                    h.bottomAnchor.constraint(equalTo: scanFrameView.bottomAnchor, constant: 2),
                    h.leadingAnchor.constraint(equalTo: scanFrameView.leadingAnchor, constant: -2),
                    h.widthAnchor.constraint(equalToConstant: length),
                    h.heightAnchor.constraint(equalToConstant: thickness),
                    v.bottomAnchor.constraint(equalTo: scanFrameView.bottomAnchor, constant: 2),
                    v.leadingAnchor.constraint(equalTo: scanFrameView.leadingAnchor, constant: -2),
                    v.widthAnchor.constraint(equalToConstant: thickness),
                    v.heightAnchor.constraint(equalToConstant: length),
                ])
            default: // bottom-right
                NSLayoutConstraint.activate([
                    h.bottomAnchor.constraint(equalTo: scanFrameView.bottomAnchor, constant: 2),
                    h.trailingAnchor.constraint(equalTo: scanFrameView.trailingAnchor, constant: 2),
                    h.widthAnchor.constraint(equalToConstant: length),
                    h.heightAnchor.constraint(equalToConstant: thickness),
                    v.bottomAnchor.constraint(equalTo: scanFrameView.bottomAnchor, constant: 2),
                    v.trailingAnchor.constraint(equalTo: scanFrameView.trailingAnchor, constant: 2),
                    v.widthAnchor.constraint(equalToConstant: thickness),
                    v.heightAnchor.constraint(equalToConstant: length),
                ])
            }
        }
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
        scanFrameView.layer.borderColor = UIColor.white.cgColor
        instructionLabel.text = "Align a LinkedIn QR code within the frame"
        instructionLabel.backgroundColor = UIColor(red: 0.30, green: 0.45, blue: 0.95, alpha: 0.9)
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
            instructionLabel.text = "Not a LinkedIn QR code"
            instructionLabel.backgroundColor = UIColor(red: 1.00, green: 0.65, blue: 0.20, alpha: 0.9)
            scanFrameView.layer.borderColor = UIColor.systemOrange.cgColor
            return
        }

        isProcessing = true
        scanFrameView.layer.borderColor = UIColor(red: 0.20, green: 0.75, blue: 0.45, alpha: 1.0).cgColor
        instructionLabel.text = "QR Code Detected"
        instructionLabel.backgroundColor = UIColor(red: 0.20, green: 0.75, blue: 0.45, alpha: 0.9)

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        delegate?.didScanQRCode(scannedValue)
    }
}
