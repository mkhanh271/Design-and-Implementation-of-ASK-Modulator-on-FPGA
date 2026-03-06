% ASK Modulation Software Simulation in MATLAB
% Mimics the Verilog hardware implementation

clear all;
close all;
clc;

%% System Parameters (from Verilog testbench)
f_clk = 50e6;           % Clock frequency: 50 MHz
T_clk = 1/f_clk;        % Clock period: 20 ns

% Phase accumulator parameters
increment = hex2dec('08000000');  % 0x08000000 from testbench
accumulator_bits = 32;

% Calculate carrier frequency
% f_carrier = (increment / 2^32) * f_clk
f_carrier = (increment / 2^accumulator_bits) * f_clk;
fprintf('Carrier Frequency: %.4f MHz\n', f_carrier/1e6);

%% Simulation Time Parameters
% Data pattern timing (from testbench):
% data=1 for 2000ns, data=0 for 2000ns, data=1 for 2000ns, 
% data=0 for 2000ns, data=1 for 2000ns
t_bit = 2000e-9;        % Each data bit duration: 2000 ns
total_time = 5 * t_bit; % Total simulation time: 10000 ns

% Sampling parameters
samples_per_clock = 10;  % Oversample for smooth visualization
f_sample = f_clk * samples_per_clock;
T_sample = 1/f_sample;
t = 0:T_sample:total_time-T_sample;

%% Generate Data Signal (OOK pattern)
% Create the data pattern: [1, 0, 1, 0, 1]
data_pattern = [1, 0, 1, 0, 1];
data_signal = zeros(size(t));

for i = 1:length(data_pattern)
    start_idx = round((i-1)*t_bit/T_sample) + 1;
    end_idx = min(round(i*t_bit/T_sample), length(t));
    data_signal(start_idx:end_idx) = data_pattern(i);
end

%% Generate Carrier Signal
% Create sine wave carrier
carrier_signal = sin(2*pi*f_carrier*t);

%% ASK Modulation (On-Off Keying)
% Multiply carrier by data signal
ask_signal = carrier_signal .* data_signal;

%% Plotting Results
figure('Position', [100, 100, 1200, 800]);

% Plot 1: Input Data Signal
subplot(3,1,1);
plot(t*1e6, data_signal, 'b', 'LineWidth', 2);
grid on;
xlabel('Time (μs)', 'FontSize', 12);
ylabel('Amplitude', 'FontSize', 12);
title('Input Data Signal (Digital Modulating Signal)', 'FontSize', 14, 'FontWeight', 'bold');
ylim([-0.2, 1.2]);
xlim([0, total_time*1e6]);

% Plot 2: Carrier Signal
subplot(3,1,2);
plot(t*1e6, carrier_signal, 'r', 'LineWidth', 1);
grid on;
xlabel('Time (μs)', 'FontSize', 12);
ylabel('Amplitude', 'FontSize', 12);
title(sprintf('Carrier Signal (f_c = %.4f MHz)', f_carrier/1e6), 'FontSize', 14, 'FontWeight', 'bold');
ylim([-1.5, 1.5]);
xlim([0, total_time*1e6]);

% Plot 3: ASK Modulated Output
subplot(3,1,3);
plot(t*1e6, ask_signal, 'g', 'LineWidth', 1);
grid on;
xlabel('Time (μs)', 'FontSize', 12);
ylabel('Amplitude', 'FontSize', 12);
title('ASK Modulated Output Signal (OOK)', 'FontSize', 14, 'FontWeight', 'bold');
ylim([-1.5, 1.5]);
xlim([0, total_time*1e6]);

sgtitle('ASK Modulation - Software Simulation in MATLAB', ...
        'FontSize', 16, 'FontWeight', 'bold');

%% Display Statistics
fprintf('\n=== Simulation Parameters ===\n');
fprintf('Sampling Frequency: %.2f MHz\n', f_sample/1e6);
fprintf('Total Simulation Time: %.2f μs\n', total_time*1e6);
fprintf('Number of Samples: %d\n', length(t));
fprintf('Data Bit Duration: %.2f μs\n', t_bit*1e6);
fprintf('Carrier Period: %.4f ns\n', (1/f_carrier)*1e9);
fprintf('Samples per Carrier Cycle: %.1f\n', f_sample/f_carrier);