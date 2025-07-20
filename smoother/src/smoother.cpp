#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <cmath>
#include <algorithm>
#include <memory>
#include <stdexcept>
#include <numeric>
#include <Eigen/Dense>
#include "nlohmann/json.hpp"

using namespace Eigen;
using json = nlohmann::json;

struct EdgeParams {
    bool enable = false;
    int window = 5;
    double weight_factor = 1.0;
    double span_ratio = 1.0;
};

struct EdgeWeightConfig {
    EdgeParams left;
    EdgeParams right;
};

struct OutlierParams {
    bool enable = false;
    int window = 5;
    double threshold = 3.0; 
};

struct OutlierDetectionConfig {
    OutlierParams left;
    OutlierParams right;
};

struct Config {
    std::string method = "moving";
    double span = 0.0;
    EdgeWeightConfig edge_weights;
    OutlierDetectionConfig outlier_detection;
};

std::string config_path      = "/etc/smoother/config.json";
std::string data_input_path  = "/var/lib/relaxtool/input/data_smoother.txt";
std::string data_output_path = "/var/lib/relaxtool/output/data_smoother.txt";

// Базовый класс для методов сглаживания
class SmoothingMethod {
public:
    virtual ~SmoothingMethod() = default;
    virtual std::vector<double> smooth(const std::vector<double>& data) const = 0;
    
    void set_edge_weights(const EdgeWeightConfig& config) {
        edge_config_ = config;
    }
    
    void set_outlier_config(const OutlierDetectionConfig& config) {
        outlier_config_ = config;
    }

protected:
    EdgeWeightConfig edge_config_;
    OutlierDetectionConfig outlier_config_;
    
    // Вспомогательная функция для вычисления MAD
    double compute_mad(const VectorXd& vec) const {
        VectorXd abs_dev = vec.cwiseAbs();
        return 1.4826 * vector_median(abs_dev);
    }
    
    double calculate_effective_span(int idx, int n, double base_span) const {
        double span = base_span;
        const auto& left = edge_config_.left;
        const auto& right = edge_config_.right;
        
        // Для левой границы
        if (left.enable && idx < left.window) {
            span = left.window * left.span_ratio / static_cast<double>(n);
        }
        
        // Для правой границы
        if (right.enable && (n - idx) <= right.window) {
            span = right.window * right.span_ratio / static_cast<double>(n);
        }
        
        return std::clamp(span, 0.0, 1.0);  // Ограничиваем диапазон
    }

    
    // Функция для вычисления медианы вектора
    double vector_median(const VectorXd& vec) const {
        std::vector<double> v(vec.data(), vec.data() + vec.size());
        auto mid = v.begin() + v.size()/2;
        std::nth_element(v.begin(), mid, v.end());
        return *mid;
    }
    
    VectorXd apply_edge_weights(const VectorXd& weights, int idx, int n) const {
        VectorXd modified = weights;
        const auto& left = edge_config_.left;
        const auto& right = edge_config_.right;

        // Обработка левой границы
        if (left.enable && idx < left.window) {
            double decay = 1.0 - static_cast<double>(idx) / left.window;
            modified *= (1.0 + (left.weight_factor - 1.0) * decay);
        }

        // Обработка правой границы
        if (right.enable && (n - idx) <= right.window) {
            double decay = 1.0 - static_cast<double>(n - idx - 1) / right.window;
            modified *= (1.0 + (right.weight_factor - 1.0) * decay);
        }

        return modified.cwiseMin(1.0).cwiseMax(0.0);
    }
    
    VectorXd compute_outlier_weights(const VectorXd& residuals, int n) const {
        VectorXd weights = VectorXd::Ones(residuals.size());
        
        // Обработка левой границы
        if (outlier_config_.left.enable) {
            int left_window = std::min(outlier_config_.left.window, n);
            VectorXd segment = residuals.head(left_window);
            double mad = compute_mad(segment);
            for (int i = 0; i < left_window; ++i) {
                if (std::abs(segment[i]) > outlier_config_.left.threshold * mad) {
                    weights[i] = 0;
                }
            }
        }
        
        // Обработка правой границы
        if (outlier_config_.right.enable) {
            int right_window = std::min(outlier_config_.right.window, n);
            VectorXd segment = residuals.tail(right_window);
            double mad = compute_mad(segment);
            for (int i = 0; i < right_window; ++i) {
                if (std::abs(segment[i]) > outlier_config_.right.threshold * mad) {
                    weights[n - right_window + i] = 0;
                }
            }
        }
        
        return weights;
    }
};

// Вспомогательные функции
VectorXd tricube_weights(const VectorXd& distances, double max_distance) {
    VectorXd weights(distances.size());
    for (int i = 0; i < distances.size(); ++i) {
double d = std::abs(distances[i]) / max_distance;
        weights[i] = (d < 1) ? std::pow(1 - std::pow(d, 3), 3) : 0;
    }
    return weights;
}

// Методы сглаживания
class MovingAverage : public SmoothingMethod {
    int span_;
public:
    MovingAverage(int span) : span_(span) {}
    
    std::vector<double> smooth(const std::vector<double>& data) const override {
        if (span_ == 0) return data;
        
        int padding = (span_ - 1) / 2;
        VectorXd vec = Map<const VectorXd>(data.data(), data.size());
        VectorXd result = vec;
        
        for (int i = 0; i < data.size(); ++i) {
            int start = std::max(0, i - padding);
            int end = std::min(static_cast<int>(data.size())-1, i + padding);
            result[i] = vec.segment(start, end-start+1).mean();
        }
        return std::vector<double>(result.data(), result.data() + result.size());
    }
};

// Базовый класс для устойчивых методов
class RobustSmoother : public virtual SmoothingMethod {
protected:
    VectorXd compute_robust_weights(const VectorXd& residuals) const {
        VectorXd abs_res = residuals.cwiseAbs();
        double mad = 1.4826 * vector_median(abs_res);
        
        VectorXd weights(residuals.size());
        for(int i = 0; i < residuals.size(); ++i) {
            double u = std::abs(residuals[i]) / (6 * mad);
            weights[i] = (u < 1) ? std::pow(1 - u*u, 2) : 0;
        }
        return weights;
    }
};

// Класс LOWESS с линейной регрессией
class Lowess : public virtual SmoothingMethod {
protected:
    double span_;
    
    VectorXd local_regression(const VectorXd& x, const VectorXd& y, 
                            double x0, const VectorXd& weights) const {
        MatrixXd X(x.size(), 2);
        X.col(0) = VectorXd::Ones(x.size());
        X.col(1) = x.array() - x0;
        
        MatrixXd W = weights.asDiagonal();
        MatrixXd XTWX = X.transpose() * W * X;
        VectorXd beta = (XTWX).ldlt().solve(X.transpose() * W * y);
        return beta;
    }

    VectorXd tricube_weights(const VectorXd& distances, double max_dist) const {
        VectorXd weights(distances.size());
        for(int i = 0; i < distances.size(); ++i) {
            double d = std::abs(distances[i]) / max_dist;
            weights[i] = (d < 1) ? std::pow(1 - std::pow(d, 3), 3) : 0;
        }
        return weights;
    }

public:
    Lowess(double span) : span_(span) {}
    
    std::vector<double> smooth(const std::vector<double>& data) const override {
        const int n = data.size();
        const int window = std::max(3, static_cast<int>(span_ * n));
        const int half_window = window / 2;
        
        VectorXd y = Map<const VectorXd>(data.data(), n);
        VectorXd smoothed(n);
        
        for(int i = 0; i < n; ++i) {
            double effective_span = calculate_effective_span(i, n, span_);
            // размер окна на основе эффективного span
            const int window = std::max(3, static_cast<int>(effective_span * n));
            const int half_window = window / 2;

            int start = std::max(0, i - half_window);
            int end = std::min(n-1, i + half_window);
            
            VectorXd x_vals = VectorXd::LinSpaced(end-start+1, start, end);
            VectorXd y_segment = y.segment(start, end-start+1);
            
            VectorXd distances = x_vals.array() - i;
            VectorXd weights = tricube_weights(distances, half_window);
            
            VectorXd final_weights = apply_edge_weights(weights, i, n);
            VectorXd beta = local_regression(x_vals, y_segment, i, final_weights);

            smoothed[i] = beta[0];
        }
        return std::vector<double>(smoothed.data(), smoothed.data() + smoothed.size());
    }
};

// Устойчивая версия LOWESS
class RLowess : public RobustSmoother, public Lowess {
public:
    RLowess(double span) : Lowess(span) {}
    
    std::vector<double> smooth(const std::vector<double>& data) const override {
        VectorXd y = Map<const VectorXd>(data.data(), data.size());
        std::vector<double> base_smoothed = Lowess::smooth(data);
        VectorXd smoothed = Map<const VectorXd>(base_smoothed.data(), base_smoothed.size());
 
        for(int iter = 0; iter < 5; ++iter) {
            VectorXd residuals = y - smoothed;
            VectorXd outlier_weights = compute_outlier_weights(residuals, y.size());
            VectorXd robustness_weights = compute_robust_weights(residuals).cwiseProduct(outlier_weights);
            
            const int n = data.size();
            const int window = std::max(3, static_cast<int>(span_ * n));
            const int half_window = window / 2;
            
            for(int i = 0; i < n; ++i) {
	            double effective_span = calculate_effective_span(i, n, span_);
	            //  размер окна на основе эффективного span
	            const int window = std::max(3, static_cast<int>(effective_span * n));
	            const int half_window = window / 2;

                int start = std::max(0, i - half_window);
                int end = std::min(n-1, i + half_window);
                
                VectorXd x_vals = VectorXd::LinSpaced(end-start+1, start, end);
                VectorXd y_segment = y.segment(start, end-start+1);
                
                VectorXd distances = x_vals.array() - i;
                VectorXd spatial_weights = tricube_weights(distances, half_window);
                VectorXd combined_weights = spatial_weights.cwiseProduct(
                    robustness_weights.segment(start, end-start+1));
                
                VectorXd final_weights = apply_edge_weights(combined_weights, i, n);
                VectorXd beta = local_regression(x_vals, y_segment, i, final_weights);
                
                smoothed[i] = beta[0];
            }
        }
        return std::vector<double>(smoothed.data(), smoothed.data() + smoothed.size());
    }
};

// Класс Loess с квадратичной регрессией
class Loess : public virtual SmoothingMethod {
protected:
    double span_;
    
    VectorXd local_regression(const VectorXd& x, const VectorXd& y, 
                            double x0, const VectorXd& weights) const {
        MatrixXd X(x.size(), 3);
        X.col(0) = VectorXd::Ones(x.size());
        X.col(1) = x.array() - x0;
        X.col(2) = X.col(1).array().square();
        
        MatrixXd W = weights.asDiagonal();
        MatrixXd XTWX = X.transpose() * W * X;
        VectorXd beta = (XTWX).ldlt().solve(X.transpose() * W * y);
        return beta;
    }

public:
    Loess(double span) : span_(span) {}
    
    std::vector<double> smooth(const std::vector<double>& data) const override {
        const int n = data.size();
        const int window = std::max(5, static_cast<int>(span_ * n));
        const int half_window = window / 2;
        
        VectorXd y = Map<const VectorXd>(data.data(), n);
        VectorXd smoothed(n);
        
        for(int i = 0; i < n; ++i) {
            double effective_span = calculate_effective_span(i, n, span_);
            // размер окна на основе эффективного span
            const int window = std::max(3, static_cast<int>(effective_span * n));
            const int half_window = window / 2;

            int start = std::max(0, i - half_window);
            int end = std::min(n-1, i + half_window);
            
            VectorXd x_vals = VectorXd::LinSpaced(end-start+1, start, end);
            VectorXd y_segment = y.segment(start, end-start+1);
            
            VectorXd weights = VectorXd::Ones(end-start+1);
            VectorXd final_weights = apply_edge_weights(weights, i, n);
            VectorXd beta = local_regression(x_vals, y_segment, i, final_weights);

            smoothed[i] = beta[0];
        }
        return std::vector<double>(smoothed.data(), smoothed.data() + smoothed.size());
    }
};

// Устойчивая версия Loess
class RLoess : public RobustSmoother, public Loess {
public:
    RLoess(double span) : Loess(span) {}
    
    std::vector<double> smooth(const std::vector<double>& data) const override {
        VectorXd y = Map<const VectorXd>(data.data(), data.size());
        std::vector<double> base_smoothed = Loess::smooth(data);
        VectorXd smoothed = Map<const VectorXd>(base_smoothed.data(), base_smoothed.size());
        
        for(int iter = 0; iter < 5; ++iter) {
            VectorXd residuals = y - smoothed;
            VectorXd outlier_weights = compute_outlier_weights(residuals, y.size());
            VectorXd robustness_weights = compute_robust_weights(residuals).cwiseProduct(outlier_weights);
            
            const int n = data.size();
            const int window = std::max(5, static_cast<int>(span_ * n));
            const int half_window = window / 2;
            
            for(int i = 0; i < n; ++i) {
	            double effective_span = calculate_effective_span(i, n, span_);
	            // размер окна на основе эффективного span
	            const int window = std::max(3, static_cast<int>(effective_span * n));
	            const int half_window = window / 2;
                int start = std::max(0, i - half_window);
                int end = std::min(n-1, i + half_window);
                
                VectorXd x_vals = VectorXd::LinSpaced(end-start+1, start, end);
                VectorXd y_segment = y.segment(start, end-start+1);
                VectorXd w_segment = robustness_weights.segment(start, end-start+1);
                
                VectorXd final_weights = apply_edge_weights(w_segment, i, n);
                VectorXd beta = local_regression(x_vals, y_segment, i, final_weights);
                
                smoothed[i] = beta[0];
            }
        }
        return std::vector<double>(smoothed.data(), smoothed.data() + smoothed.size());
    }
};

class SGolay : public SmoothingMethod {
    int window_;
    int poly_order_;
    VectorXd coefficients_;
    
    void calculate_coefficients() {
        const int m = (window_ - 1)/2;
        MatrixXd A(window_, poly_order_ + 1);
        
        for(int i = 0; i < window_; ++i) {
            int x = i - m;
            for(int j = 0; j <= poly_order_; ++j) {
                A(i, j) = std::pow(x, j);
            }
        }
        
        MatrixXd ATA = A.transpose() * A;
        coefficients_ = ATA.ldlt().solve(A.transpose()).row(0);
    }

    VectorXd calculate_adjusted_coefficients(int actual_window) const {
        const int m = (actual_window - 1)/2;
        MatrixXd A(actual_window, poly_order_ + 1);
        
        for(int i = 0; i < actual_window; ++i) {
            int x = i - m;
            for(int j = 0; j <= poly_order_; ++j) {
                A(i, j) = std::pow(x, j);
            }
        }
        
        MatrixXd ATA = A.transpose() * A;
        return ATA.ldlt().solve(A.transpose()).row(0);
    }

public:
    SGolay(int window, int poly_order = 2) : 
        window_(window), poly_order_(poly_order) {
        if(window % 2 == 0) throw std::invalid_argument("Window must be odd");
        calculate_coefficients();
    }
    
    std::vector<double> smooth(const std::vector<double>& data) const override {
        const int n = data.size();
        const int padding = (window_ - 1)/2;
        
        VectorXd vec = Map<const VectorXd>(data.data(), data.size());
        VectorXd result = VectorXd::Zero(n);
        
        for(int i = 0; i < n; ++i) {
            int start = std::max(0, i - padding);
            int end = std::min(n-1, i + padding);
            int actual_window = end - start + 1;
            
            VectorXd coeffs = (actual_window == window_) ? 
                coefficients_ : 
                calculate_adjusted_coefficients(actual_window);
            
            result[i] = coeffs.dot(vec.segment(start, actual_window));
        }
        return std::vector<double>(result.data(), result.data() + result.size());
    }
};

// Фабрика методов сглаживания
std::unique_ptr<SmoothingMethod> create_smoothing_method(
    const std::string& method, 
    double span,
    const EdgeWeightConfig& edge_config,
    const OutlierDetectionConfig& outlier_config
) {
    std::unique_ptr<SmoothingMethod> smoother;

    if (method == "moving") {
        int span_int = static_cast<int>(span);
        if (span != static_cast<double>(span_int)) {
            throw std::invalid_argument("Span for moving average must be integer");
        }
        smoother = std::make_unique<MovingAverage>(span_int);
    }
    else if (method == "lowess") {
        smoother = std::make_unique<Lowess>(span);
    }
    else if (method == "loess") {
        smoother = std::make_unique<Loess>(span);
    }
    else if (method == "sgolay") {
        int span_int = static_cast<int>(span);
        if (span != static_cast<double>(span_int)) {
            throw std::invalid_argument("Span for SGolay must be integer");
        }
        smoother = std::make_unique<SGolay>(span_int);
    }
    else if (method == "rlowess") {
        smoother = std::make_unique<RLowess>(span);
    }
    else if (method == "rloess") {
        smoother = std::make_unique<RLoess>(span);
    }
    else {
        throw std::invalid_argument("Unknown smoothing method: " + method);
    }

    // Установка параметров краевых весов и обнаружения выбросов
    smoother->set_edge_weights(edge_config);
    smoother->set_outlier_config(outlier_config);
    
    return smoother;
}

// Чтение данных из файла
std::vector<double> read_data(const std::string& filename) {
    std::ifstream file(filename);
    if (!file.is_open()) {
        throw std::runtime_error("Failed to open data file: " + filename);
    }
    std::vector<double> data;
    double value;
    while (file >> value) {
        data.push_back(value);
    }
    return data;
}

// Чтение конфигурации из JSON
Config read_config(const std::string& filename) {
    std::ifstream file(filename);
    if (!file.is_open()) {
        throw std::runtime_error("Failed to open config file: " + filename);
    }
    json j;
    file >> j;
    Config config;
    
    if (j.contains("method")) {
        config.method = j["method"].get<std::string>();
    }
    if (j.contains("span")) {
        config.span = j["span"].get<double>();
    }
    
    // Чтение настроек краевых весов
    if (j.contains("edge_weights")) {
        auto& ew = j["edge_weights"];
        if (ew.contains("left")) {
            config.edge_weights.left.enable = ew["left"]["enable"];
            config.edge_weights.left.window = ew["left"]["window"];
            config.edge_weights.left.weight_factor = ew["left"]["weight_factor"];
        }
        if (ew.contains("right")) {
            config.edge_weights.right.enable = ew["right"]["enable"];
            config.edge_weights.right.window = ew["right"]["window"];
            config.edge_weights.right.weight_factor = ew["right"]["weight_factor"];
        }
    }
    
    // Чтение настроек обнаружения выбросов
    if (j.contains("outlier_detection")) {
        auto& od = j["outlier_detection"];
        if (od.contains("left")) {
            config.outlier_detection.left.enable = od["left"]["enable"];
            config.outlier_detection.left.window = od["left"]["window"];
            config.outlier_detection.left.threshold = od["left"]["threshold"];
        }
        if (od.contains("right")) {
            config.outlier_detection.right.enable = od["right"]["enable"];
            config.outlier_detection.right.window = od["right"]["window"];
            config.outlier_detection.right.threshold = od["right"]["threshold"];
        }
    }
    
    return config;
}

// Запись результата в файл
void write_data(const std::string& filename, const std::vector<double>& data) {
    std::ofstream file(filename);
    if (!file.is_open()) {
        throw std::runtime_error("Failed to open output file: " + filename);
    }
    for (const auto& val : data) {
        file << val << std::endl;
    }
}

int main() {
    try {
	if (!std::filesystem::exists(config_path)) {
	  // Fallback to local dir for development
	  data_input_path = "data_smoother.txt";
	}
	if (!std::filesystem::exists(config_path)) {
	  // Fallback to local dir for development
	  config_path = "config.json";
	}
	if (!std::filesystem::exists(config_path)) {
	  // Fallback to local dir for development
	  data_output_path = "data_smoother.txt";
	}
        auto data = read_data(data_input_path);
        auto config = read_config(config_path);
        auto method = create_smoothing_method(
            config.method, 
            config.span, 
            config.edge_weights,
            config.outlier_detection
        );
        auto smoothed_data = method->smooth(data);
        write_data(data_output_path, smoothed_data);
        std::cout << "Data smoothed successfully using method: " << config.method << std::endl;
    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }
    return 0;
}
