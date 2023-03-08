import UIKit

final class MovieQuizViewController: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var textLabel: UILabel!
    @IBOutlet private var counterLabel: UILabel!
    @IBOutlet private var yesButton: UIButton!
    @IBOutlet private var noButton: UIButton!
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Private properties

    private var correctAnswers: Int = 0
    private var questionFactory: QuestionFactoryProtocol?
    private var currentQuestion: QuizQuestion?
    private var alertPresenter: AlertPresenterProtocol?
    private var statisticService: StatisticService?
    private var presenter = MovieQuizPresenter()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        alertPresenter = AlertPresenter(viewController: self)
        questionFactory = QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)
        statisticService = StatisticServiceImplementation()
        activityIndicator.startAnimating()
        questionFactory?.loadData()
        presenter.viewController = self
    }
    
    // MARK: - Actions
    
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        presenter.currentQuestion = currentQuestion
        presenter.yesButtonClicked()
    }
    
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        presenter.currentQuestion = currentQuestion
        presenter.yesButtonClicked()
    }
    
    // MARK: - Private functions

    private func showNetworkError(message: String) {
        activityIndicator.stopAnimating()
        
        let alert = AlertModel(
            title: "Ошибка",
            message: message,
            buttonText: "Попробовать ещё раз"
        ) { [ weak self ] in
            guard let self = self else { return }
            
            self.activityIndicator.startAnimating()
            self.questionFactory?.loadData()
        }
        
        alertPresenter?.showAlert(model: alert)
    }
    
    private func show(quiz step: QuizStepViewModel) {
        imageView.image = step.image
        imageView.layer.borderColor = UIColor.clear.cgColor
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
    }
        
    func showAnswerResult(isCorrect: Bool) {
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.cornerRadius = 20
        yesButton.isEnabled = false // отключаем для наших кнопок возможность повторного нажатия
        noButton.isEnabled = false  // на время проверки правильности ответа
        
        if isCorrect {
            imageView.layer.borderColor = UIColor.ypGreen.cgColor
            correctAnswers += 1
        } else {
            imageView.layer.borderColor = UIColor.ypRed.cgColor
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            
            self.showNextQuestionOrResults()
            self.yesButton.isEnabled = true // включаем для наших кнопок возможность нажатия после проверки
            self.noButton.isEnabled = true
        }
    }
    
    private func showNextQuestionOrResults() {
        if presenter.isLastQuestion() {
            guard let statisticService = statisticService else {
                return
            }
            
            statisticService.store(correct: correctAnswers, total: presenter.questionsAmount)
            
            let alertMessage = """
Ваш результат: \(correctAnswers) из \(presenter.questionsAmount)
Количество сыгранных квизов: \(statisticService.gameCount)
Рекорд: \(statisticService.bestGame.correct)/\(statisticService.bestGame.total) (\(statisticService.bestGame.date.dateTimeString))
Средняя точность: \(String(format: "%.2f", statisticService.totalAccuracy))%
"""
            
            let alert = AlertModel(
                title: "Этот раунд окончен!",
                message: alertMessage,
                buttonText: "Сыграть ещё раз",
                completion: { [weak self] in
                    guard let self = self else { return }
                    
                    self.presenter.resetQuestionIndex()
                    self.correctAnswers = 0
                    self.questionFactory?.requestNextQuestion()
                }
            )
            
            alertPresenter?.showAlert(model: alert)
        } else {
            presenter.switchToNextQuestion()
            questionFactory?.requestNextQuestion()
        }
    }
}

extension MovieQuizViewController: QuestionFactoryDelegate {
    
    // MARK: - QuestionFactoryDelegate
    
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else {
            return
        }
        
        currentQuestion = question
        let viewModel = presenter.convert(model: question)
        DispatchQueue.main.async { [weak self] in
            self?.show(quiz: viewModel)
        }
    }
    
    func didLoadDataFromServer() {
        activityIndicator.stopAnimating()
        questionFactory?.requestNextQuestion() // показываем первый вопрос
    }
    
    func didFailToLoadData(with error: String) {
        showNetworkError(message: error) // возьмём в качестве сообщения описание ошибки
    }
}

