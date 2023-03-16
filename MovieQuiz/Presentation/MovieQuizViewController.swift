import UIKit

final class MovieQuizViewController: UIViewController, MovieQuizViewControllerProtocol {
    
    // MARK: - Outlets
    
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var textLabel: UILabel!
    @IBOutlet private var counterLabel: UILabel!
    @IBOutlet private var yesButton: UIButton!
    @IBOutlet private var noButton: UIButton!
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Private properties

    private var presenter: MovieQuizPresenter?
    private var alertPresenter: AlertPresenterProtocol?
    private var feedbackGenerator = UINotificationFeedbackGenerator()
    
    // MARK: - Overridden properties
    
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        presenter = MovieQuizPresenter(viewController: self)
        alertPresenter = AlertPresenter(viewController: self)
    }
    
    // MARK: - Actions
    
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        guard presenter?.yesButtonClicked() == true else {
            return shake(element: yesButton)
        }
    }
    
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        guard presenter?.noButtonClicked() == true else {
            return shake(element: noButton)
        }
    }
    
    // MARK: - Functions
    
    func show(quiz step: QuizStepViewModel) {
        imageView.image = step.image
        imageView.layer.borderColor = UIColor.clear.cgColor
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
    }
    
    func showQuizResults(model alert: AlertModel) {
        alertPresenter?.showAlert(model: alert)
    }
    
    func highlightImageBorder(isCorrectAnswer: Bool) {
        if isCorrectAnswer {
            feedbackGenerator.notificationOccurred(.success)
        } else {
            feedbackGenerator.notificationOccurred(.error)
        }
        
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.cornerRadius = 20
        imageView.layer.borderColor = isCorrectAnswer ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
        yesButton.isEnabled = false // отключаем для наших кнопок возможность повторного нажатия
        noButton.isEnabled = false  // на время проверки правильности ответа
    }
    
    func enableButtons() {
        yesButton.isEnabled = true
        noButton.isEnabled = true
    }
    
    func showLoadingIndicator() {
        activityIndicator.startAnimating()
    }
    
    func hideLoadingIndicator() {
        activityIndicator.stopAnimating()
    }
    
    func shake(element: UIButton) {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")

        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        animation.duration = 0.5
        animation.values = [-10.0, 10.0, -10.0, 10.0, -6.0, 6.0, -3.0, 3.0, 0.0]

        element.layer.add(animation, forKey: "shake")
    }
    
    func showNetworkError(message: String) {
        hideLoadingIndicator()
        
        let alert = AlertModel(
            title: "Ошибка",
            message: message,
            buttonText: "Попробовать ещё раз"
        ) { [ weak self ] in
            guard let self = self else { return }
            
            self.showLoadingIndicator()
            self.presenter?.questionFactoryLoadData()
        }
        
        alertPresenter?.showAlert(model: alert)
    }
}
