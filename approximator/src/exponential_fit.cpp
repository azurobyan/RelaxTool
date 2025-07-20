#include <iostream>
#include <vector>
#include <Eigen/Dense>
#include <cmath>
#include <algorithm>
#include <numeric>
#include <functional>
#include <limits>

using namespace Eigen;
using namespace std;

// Конфигурация алгоритма
const double ALPHA = 1.0;
const double GAMMA = 2.0;
const double RHO = 0.5;
const double SIGMA = 0.5;
const double MIN_B = 1e-3;
const double MAX_B = 1e+3;
const double INIT_LAMBDA = 1e-3;
const double LAMBDA_FACTOR = 10.0;
const int MAX_ITER = 1000;
const double TOLERANCE = 1e-8;

double model(double x, const VectorXd& params, int n) {
    double y = params[0];
    for(int i=0; i<n; i++){
        double a = params[1+2*i];
        double b = max(params[2+2*i], MIN_B);
        y += a * exp(-x/(b + 1e-9));
    }
    return y;
}

double sse(const vector<double>& x, const vector<double>& y, const VectorXd& params, int n) {
    double error = 0.0;
    for(size_t i=0; i<x.size(); ++i) {
        double diff = y[i] - model(x[i], params, n);
        error += diff * diff;
    }
    return error;
}
VectorXd levenberg_marquardt(
    const vector<double>& x, 
    const vector<double>& y, 
    int n_exponents, 
    int max_iter = MAX_ITER, 
    double tol = TOLERANCE
) {
    const int m = x.size();
    const int num_params = 1 + 2 * n_exponents;
    
    // 1. Инициализация параметров
    VectorXd params(num_params);
    params.setZero();
    
    // a0 = среднее Y (работает и норм)
    params[0] = VectorXd::Map(y.data(), y.size()).mean();
    
    // a_i и b_i: равномерное распределение
    const double y_amplitude = (*max_element(y.begin(), y.end()) 
                              - *min_element(y.begin(), y.end()));
    const double x_range = *max_element(x.begin(), x.end()) 
                         - *min_element(x.begin(), x.end());
    
    for(int i = 0; i < n_exponents; ++i) {
        params[1 + 2*i] = y_amplitude / n_exponents;  // a_i
        params[2 + 2*i] = x_range / (i + 1);         // b_i
    }

    // 2. Основной цикл оптимизации
    MatrixXd J(m, num_params);
    VectorXd residuals(m);
    double lambda = INIT_LAMBDA;
    
    for(int iter = 0; iter < max_iter; ++iter) {
        // 2.1 Вычисление остатков
        for(int i = 0; i < m; ++i) {
            residuals[i] = y[i] - model(x[i], params, n_exponents);
        }
        
        // 2.2 Построение Якобиана
        J.setZero();
        for(int i = 0; i < m; ++i) {
            const double xi = x[i];
            J(i, 0) = 1.0;  // df/da0
            
            for(int j = 0; j < n_exponents; ++j) {
                const double a = params[1 + 2*j];
                const double b = params[2 + 2*j];
                const double exp_term = exp(-xi / b);
                
                // df/da_j
                J(i, 1 + 2*j) = exp_term;
                
                // df/db_j
                J(i, 2 + 2*j) = a * xi * exp_term / (b * b);
            }
        }

        // 2.3 Решение системы (J^T J + λ diag(J^T J)) δ = J^T r
        MatrixXd JTJ = J.transpose() * J;
        VectorXd diag = JTJ.diagonal().cwiseMax(1e-6);  // Защита от нулей на диагонале 
        JTJ += lambda * diag.asDiagonal();
        
        VectorXd delta = JTJ.ldlt().solve(J.transpose() * residuals);
        
        // 2.4 Обновление параметров с ограничениями
        VectorXd new_params = params + delta;
        for(int j = 0; j < n_exponents; ++j) {
            // Ограничение b_j
            new_params[2 + 2*j] = clamp(
                new_params[2 + 2*j], 
                MIN_B, 
                MAX_B
            );
        }

        // 2.5 Проверка улучшения
        double sse_old = residuals.squaredNorm();
        double sse_new = 0.0;
        for(int i = 0; i < m; ++i) {
            double error = y[i] - model(x[i], new_params, n_exponents);
            sse_new += error * error;
        }

        if(sse_new < sse_old) {
            params = new_params;
            lambda /= LAMBDA_FACTOR;
            
            // Проверка сходимости
            if(delta.norm() < tol) break;
        } else {
            lambda *= LAMBDA_FACTOR;
        }
    }
    
    return params;
}


VectorXd nelder_mead(const vector<double>& x, const vector<double>& y, int n, int max_iter=1000) {
    const int dim = 1 + 2*n;
    vector<VectorXd> simplex(dim + 1);
    vector<double> values(dim + 1);

    // Инициализация
    VectorXd base(dim);
    base[0] = y.back();
    for(int i=0; i<n; i++) {
        base[1+2*i] = 1.0;
        base[2+2*i] = x.back()/(i+1);
    }

    // Генерация симплекса
    for(int i=0; i<=dim; i++) {
        simplex[i] = base;
        if(i > 0) simplex[i][i-1] *= 1.1;
    }

    // Компаратор для сортировки
    auto comparator = [&](size_t i1, size_t i2) {
        return values[i1] < values[i2];
    };

    for(int iter=0; iter<max_iter; iter++) {
        // Вычисление значений
        for(int i=0; i<=dim; i++) 
            values[i] = sse(x, y, simplex[i], n);

        // Сортировка индексов
        vector<size_t> idx(dim+1);
        iota(idx.begin(), idx.end(), 0);
        sort(idx.begin(), idx.end(), comparator);

        // Проверка сходимости
        double range = 0.0;
        for(auto& v : simplex)
            range = max(range, (v - simplex[idx[0]]).norm());
        if(range < 1e-6) break;

        // Алгоритм Нелдера-Мида
        VectorXd centroid = VectorXd::Zero(dim);
        for(int i=0; i<dim; i++)
            centroid += simplex[idx[i]];
        centroid /= dim;

        // Отражение
        VectorXd xr = centroid + ALPHA*(centroid - simplex[idx[dim]]);
        xr[2] = clamp(xr[2], MIN_B, MAX_B);
        double fr = sse(x, y, xr, n);

        if(fr < values[idx[0]]) {
            VectorXd xe = centroid + GAMMA*(xr - centroid);
            xe[2] = clamp(xe[2], MIN_B, MAX_B);
            double fe = sse(x, y, xe, n);
            simplex[idx[dim]] = (fe < fr) ? xe : xr;
        }
        else if(fr < values[idx[dim-1]]) {
            simplex[idx[dim]] = xr;
        }
        else {
            VectorXd xc = centroid + RHO*(simplex[idx[dim]] - centroid);
            xc[2] = clamp(xc[2], MIN_B, MAX_B);
            double fc = sse(x, y, xc, n);
            if(fc < values[idx[dim]]) {
                simplex[idx[dim]] = xc;
            }
            else {
                for(int i=1; i<=dim; i++)
                    simplex[idx[i]] = simplex[idx[0]] + SIGMA*(simplex[idx[i]] - simplex[idx[0]]);
            }
        }
    }

    // поиск лучшей точки
    int best_idx = 0;
    double min_sse = numeric_limits<double>::max();
    for(int i=0; i<=dim; i++) {
        double current = sse(x, y, simplex[i], n);
        if(current < min_sse) {
            min_sse = current;
            best_idx = i;
        }
    }
    return simplex[best_idx];
}

int main(int argc, char** argv) {
    string method = "lm";  // По умолчанию Левенберг-Марквардт
    if(argc > 1) method = argv[1];

    int m, n;
    cin >> m;
    
    vector<double> x(m), y(m);
    for(int i=0; i<m; ++i) cin >> x[i];
    for(int i=0; i<m; ++i) cin >> y[i];
    cin >> n;

    VectorXd params;
    if (method == "lm") {
        params = levenberg_marquardt(x, y, n);
    } else if (method == "nm") {
        params = nelder_mead(x, y, n);
    }

    cout << "RESULTS_START" << endl;
    cout << params[0] << endl;
    for(int i=0; i<n; ++i) {
        cout << params[1+2*i] << " " << params[2+2*i] << endl;
    }
    cout << "RESULTS_END" << endl;
    
    return 0;
}
