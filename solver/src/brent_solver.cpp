#include <iostream>
#include <fstream>
#include <vector>
#include <cmath>
#include <string>
#include <map>
#include <nlohmann/json.hpp>

using namespace std;
using json = nlohmann::json;

// Коэффициенты функции из текстового файла
struct Coefficients {
    double a0;
    vector<double> a;
    vector<double> b;
};

// Параметры алгоритма из JSON
struct SolverConfig {
    double interval_start = 0.0;
    double interval_end = 10.0;
    double tolerance = 1e-6;
    int max_iterations = 100;
};
string config_file = "/etc/solver/config_solver.json";
string input_file = "/var/lib/relaxtool/input/data_solver.txt";

// Функция f(x) = a0 + sum(a[i] * exp(-x / b[i]))
double f(double x, const Coefficients& coeffs) {
    double result = coeffs.a0;
    for (size_t i = 0; i < coeffs.a.size(); ++i) {
        result += coeffs.a[i] * exp(-x / coeffs.b[i]);
    }
    return result;
}

// Метод Брента 
    double brent(double a, double b, const Coefficients& coeffs, double tol = 1e-6, int max_iter = 100) {
    double fa = f(a, coeffs);
    double fb = f(b, coeffs);
    
    if (fa * fb >= 0) {
        throw invalid_argument("[f(a), f(b)] must bracket the root");
    }

    if (abs(fa) < abs(fb)) {
        swap(a, b);
        swap(fa, fb);
    }

    double c = a, fc = fa;
    bool mflag = true;
    double d = 0.0;
    double s = 0.0;
    double fs = 0.0;

    for (int iter = 0; iter < max_iter; ++iter) {
        if (fb == 0 || abs(b - a) < tol) {
            return b;
        }

        // Вычисление нового шага
        if (fa != fc && fb != fc) {
            // Обратная квадратичная интерполяция
            s = (a * fb * fc) / ((fa - fb) * (fa - fc)) 
              + (b * fa * fc) / ((fb - fa) * (fb - fc)) 
              + (c * fa * fb) / ((fc - fa) * (fc - fb));
        } else {
            // Метод секущих
            s = b - fb * (b - a) / (fb - fa);
        }

        // Проверка условий для выбора метода
        double cond1 = (s < (3*a + b)/4) || (s > b);
        double cond2 = mflag && (abs(s - b) >= 0.5 * abs(b - c));
        double cond3 = !mflag && (abs(s - b) >= 0.5 * abs(c - d));

        if (cond1 || cond2 || cond3) {
            s = (a + b) / 2; // Бисекция
            mflag = true;
        } else {
            mflag = false;
        }

        fs = f(s, coeffs);
        d = c;
        c = b;
        fc = fb;

        // Обновление интервала
        if (fa * fs < 0) {
            b = s;
            fb = fs;
        } else {
            a = s;
            fa = fs;
        }

        // Перестановка для минимизации ошибки
        if (abs(fa) < abs(fb)) {
            swap(a, b);
            swap(fa, fb);
        }
    }

    throw runtime_error("Достигнут лимит итераций");
}

// Чтение коэффициентов из текстового файла
Coefficients read_coefficients(const string& filename) {
    ifstream file(filename);
    if (!file) throw runtime_error("Coefficients file not found: " + filename);

    Coefficients coeffs;
    file >> coeffs.a0;

    double a, b;
    while (file >> a >> b) {
        coeffs.a.push_back(a);
        coeffs.b.push_back(b);
    }
    return coeffs;
}

// Чтение конфигурации из JSON
SolverConfig read_config(const string& filename) {
    ifstream file(filename);
    if (!file) throw runtime_error("Config file not found: " + filename);

    json j;
    file >> j;

    SolverConfig cfg;
    cfg.interval_start = j.value("a", 0.0);
    cfg.interval_end = j.value("b", 10.0);
    cfg.tolerance = j.value("tol", 1e-6);
    cfg.max_iterations = j.value("max_iter", 100);
    
    return cfg;
}

// Парсинг аргументов командной строки
map<string, string> parse_args(int argc, char* argv[]) {
    map<string, string> args;
    for (int i = 1; i < argc; ++i) {
        string arg = argv[i];
        if (arg.substr(0, 2) == "--") {
            string key = arg.substr(2);
            if (i + 1 < argc && argv[i + 1][0] != '-') {
                args[key] = argv[++i];
            }
        }
    }
    return args;
}

int main(int argc, char* argv[]) {
    try {
        auto args = parse_args(argc, argv);
        
        // Загрузка конфигурации
        SolverConfig config;
        config = read_config(config_file);

        // Переопределение параметров из CLI
        if (args.count("a")) config.interval_start = stod(args["a"]);
        if (args.count("b")) config.interval_end = stod(args["b"]);
        if (args.count("tol")) config.tolerance = stod(args["tol"]);
        if (args.count("max_iter")) config.max_iterations = stoi(args["max_iter"]);

        // Чтение коэффициентов
        Coefficients coeffs = read_coefficients(input_file);

        // Поиск корня
        double root = brent(
            config.interval_start,
            config.interval_end,
            coeffs,
            config.tolerance,
            config.max_iterations
        );

        cout.precision(10);
        cout << "Root: " << root << endl;

    } catch (const exception& e) {
        cerr << "Error: " << e.what() << endl;
        return 1;
    }
    return 0;
}
