#!/usr/bin/python3
import json
import matplotlib.pyplot as plt
import numpy as np
import os
import re

def load_json(filename):
    with open(filename, 'r') as f:
        return json.load(f)

def sanitize_filename(title):
    return re.sub(r'[\\/*?:"<>|]', "_", title)

def ensure_directory_exists(path):
    """Создает директорию, если она не существует"""
    if not os.path.exists(path):
        os.makedirs(path, exist_ok=True)

def plot_single_dataset(dataset, config, index, output_dir):
    plt.figure(figsize=config.get('figure_size', [10, 5]))
    
    x = dataset['Data']['xData']
    y = np.array(dataset['Data']['yData'])
    y[y == -1] = np.nan
    
    color = config['colors'][index % len(config['colors'])]
    linestyle = config['line_styles'][index % len(config['line_styles'])]
    marker = config['marker_styles'][index % len(config['marker_styles'])]
    
    plt.plot(x, y, 
             color=color,
             linestyle=linestyle,
             marker=marker,
             linewidth=2,
             markersize=8)
    
    plt.xlabel(config.get('xlabel', 'X Axis'))
    plt.ylabel(config.get('ylabel', 'Y Axis'))
    plt.title(dataset['Title'], fontsize=14, pad=20)
    
    if config.get('grid', True):
        plt.grid(True, linestyle=':', alpha=0.7)
    
    # Формирование пути сохранения
    filename = sanitize_filename(dataset['Title'])
    full_path = os.path.join(output_dir, f"{filename}.{config.get('output_format', 'png')}")
    
    plt.savefig(
        full_path,
        dpi=config.get('dpi', 300),
        bbox_inches='tight'
    )
    plt.close()

if __name__ == "__main__":
    config = load_json('/etc/parser/config.json')
    datasets = load_json('/var/lib/relaxtool/input/plot_data.json')
    
    # Получаем путь из конфига или используем значение по умолчанию
    output_directory = config.get('output_directory', 'saved_data')
    ensure_directory_exists(output_directory)
    
    for idx, dataset in enumerate(datasets):
        try:
            assert len(dataset['Data']['xData']) == len(dataset['Data']['yData'])
            plot_single_dataset(dataset, config, idx, output_directory)
            print(f"График {dataset['Title']} сохранен в: {output_directory}/")
        except Exception as e:
            print(f"Ошибка для {dataset['Title']}: {str(e)}")
