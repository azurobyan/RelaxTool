#!/usr/bin/python3
import json
import argparse
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns  # Добавляем импорт seaborn
from matplotlib import style
import subprocess
import sys
from pathlib import Path

def load_config(config_path):
    with open(config_path) as f:
        return json.load(f)

def parse_arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument('-c', '--config', type=str, help='Path to config file')
    parser.add_argument('-n', '--n-exponents', type=int)
    parser.add_argument('-f', '--file', type=str)
    parser.add_argument('-m', '--method', choices=['nm', 'lm'])
    parser.add_argument('--plot-type', choices=['plot', 'bar', 'scatter', 'all'])
    parser.add_argument('--save', action='store_true')
    parser.add_argument('--eval', action='store_true')
    return parser.parse_args()

def merge_configs(file_config, cli_args):
    config = file_config.copy()
    
    if cli_args.n_exponents: 
        config['optimization']['n_exponents'] = cli_args.n_exponents
    if cli_args.file:
        config['data']['input_file'] = cli_args.file
    if cli_args.method:
        config['optimization']['method'] = cli_args.method
    if cli_args.plot_type:
        config['plot']['type'] = cli_args.plot_type
        
    return config

def run_fit(config):
    cmd = [
        '/usr/local/share/approximator/scripts/fit_exponential.sh',
        '-n', str(config['optimization']['n_exponents']),
        '-m', config['optimization']['method'],
        '-f', config['data']['input_file']
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    # Парсинг результатов между RESULTS_START и RESULTS_END
    start_idx = result.stdout.find('RESULTS_START') + len('RESULTS_START\n')
    end_idx = result.stdout.find('RESULTS_END')
    params_data = result.stdout[start_idx:end_idx].strip().split('\n')
    
    a0 = float(params_data[0])
    params = []
    for line in params_data[1:]:
        a, b = map(float, line.split())
        params.extend([a, b])
        
    return a0, params

def plot_results(x, y, y_pred, config, args):
    # стиль seaborn, если он указан
    if config['style'] == 'seaborn':
        sns.set_style("whitegrid")  # стиль seaborn
    else:
        plt.style.use(config['plot']['style'])  # другие стили matplotlib
    
    fig = plt.figure(figsize=(10, 6))
    
    plot_type = config['type']
    
    if plot_type == 'all':
        plots = ['plot', 'bar', 'scatter']
    else:
        plots = [plot_type]
    
    for idx, plot_type in enumerate(plots, 1):
        ax = fig.add_subplot(1, len(plots), idx)
        
        if plot_type == 'plot':
            ax.plot(x, y, 'bo', label='Data')
            ax.plot(x, y_pred, 'r-', label='Fit')
        elif plot_type == 'bar':
            ax.bar(x, y, width=0.1, label='Data')
            ax.plot(x, y_pred, 'r-', label='Fit')
        elif plot_type == 'scatter':
            ax.scatter(x, y, c='blue', label='Data')
            ax.scatter(x, y_pred, c='red', label='Fit')
        
        ax.set_title(config['title'])
        ax.set_xlabel(config['xlabel'])
        ax.set_ylabel(config['ylabel'])
        ax.grid(config['grid'])
        ax.legend()
    
    if config['save_path'] and (config['type'] == 'all' or args.save):
        Path(config['save_path']).parent.mkdir(exist_ok=True)
        plt.savefig(config['save_path'], dpi=config['dpi'])
    
    if not config['save_path'] or config['type'] != 'all':
        plt.show()

def evaluate_model(y_true, y_pred, config):
    metrics = {}
    
    if 'mse' in config['metrics']:
        metrics['MSE'] = np.mean((y_true - y_pred)**2)
    
    if 'mae' in config['metrics']:
        metrics['MAE'] = np.mean(np.abs(y_true - y_pred))
    
    if 'r2' in config['metrics']:
        ss_res = np.sum((y_true - y_pred)**2)
        ss_tot = np.sum((y_true - np.mean(y_true))**2)
        metrics['R²'] = 1 - (ss_res / ss_tot)
    
    if config['report_file']:
        with open(config['report_file'], 'w') as f:
            for name, value in metrics.items():
                f.write(f"{name}: {value:.6f}\n")
    
    print("\nModel Evaluation:")
    for name, value in metrics.items():
        print(f"{name}: {value:.6f}")

def main():
    args = parse_arguments()
    
    # Загрузка конфигурации
    config = load_config(args.config) if args.config else {}
    config = merge_configs(config, args)
    
    # Запуск оптимизации
    a0, params = run_fit(config)
    
    # Загрузка данных
    data = np.loadtxt(config['data']['input_file'])
    x = data[:, config['data']['x_column']]
    y = data[:, config['data']['y_column']]
    
    # Расчет предсказаний
    y_pred = a0 + np.zeros_like(x)
    for i in range(config['optimization']['n_exponents']):
        a = params[2*i]
        b = params[2*i+1]
        y_pred += a * np.exp(-x/b)
    
    # Оценка модели
    if args.eval or ('evaluation' in config):
        evaluate_model(y, y_pred, config['evaluation'])

    # Визуализация
    if 'plot' in config:
        plot_results(x, y, y_pred, config['plot'], args)
    

if __name__ == "__main__":
    main()
