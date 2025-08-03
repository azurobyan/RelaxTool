#!/usr/bin/python3
import json
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib as mpl

def plot_results(config_path):
    with open(config_path) as f:
        config = json.load(f)
    
    plot_cfg = config.get('plot_settings', {})
    
    # Проверка доступных стилей
    available_styles = plt.style.available
    selected_style = plot_cfg.get('style', 'ggplot')
    
    if selected_style not in available_styles:
        print(f"Warning: Style '{selected_style}' not found. Available styles: {available_styles}")
        selected_style = 'default'
    
    plt.style.use(selected_style)
    mpl.rcParams['font.family'] = 'DejaVu Sans'

    df = pd.DataFrame()
    try:
        if plot_cfg.get('show_original', True):
            df['original'] = pd.read_csv(config['input_file'], header=None).squeeze()
        if plot_cfg.get('show_smoothed', True):
            df['smoothed'] = pd.read_csv(config['output_file'], header=None).squeeze()
    except Exception as e:
        print(f"Error reading data files: {e}")
        return

    fig, ax = plt.subplots(figsize=plot_cfg.get('figsize', [12, 6]))
    
    linewidth = plot_cfg.get('linewidth', 1.5)
    colors = plot_cfg.get('colors', {})
    
    if 'original' in df:
        ax.plot(
            df['original'],
            label='Original Data',
            color=colors.get('original', '#1f77b4'),
            linewidth=linewidth,
            alpha=0.7
        )
    
    if 'smoothed' in df:
        ax.plot(
            df['smoothed'],
            label='Smoothed Data',
            color=colors.get('smoothed', '#ff7f0e'),
            linewidth=linewidth
        )
    
    ax.set_title(plot_cfg.get('title', 'Smoothing Results'))
    ax.set_xlabel(plot_cfg.get('xlabel', 'Samples'))
    ax.set_ylabel(plot_cfg.get('ylabel', 'Value'))
    
    if plot_cfg.get('grid', True):
        ax.grid(True, linestyle='--', alpha=0.6)
    
    if plot_cfg.get('legend', True):
        ax.legend()
    
    if 'output_image' in plot_cfg:
        try:
            plt.savefig(
                plot_cfg['output_image'],
                dpi=plot_cfg.get('dpi', 300),
                bbox_inches='tight'
            )
            print(f"Plot saved to {plot_cfg['output_image']}")
        except Exception as e:
            print(f"Error saving plot: {e}")
    
#    plt.show()
    plt.close()

if __name__ == "__main__":
    import sys
    config_file = sys.argv[1] if len(sys.argv) > 1 else "/etc/smoother/config.json"
    plot_results(config_file)
