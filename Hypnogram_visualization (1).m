clear all, close all, clc
%% Import data
% Define the directory containing the Excel files
folder_path = 'R:\Research\Wearable_validation_paper\BME Sleep lab\Hypnogram ( raw data)\Hypnogram_Codename';

% Get a list of all Excel files in the directory
files = dir(fullfile(folder_path, '*.xlsx'));

% If there is only one Excel file or you want the first one, you can select it like this
file_name = files(12).name;

% Construct the full file path
file_path = fullfile(folder_path, file_name);
% Set up the Import Options and import the data
opts = spreadsheetImportOptions("NumVariables", 6);
% Specify sheet and range
% opts.Sheet = "Sheet1";
opts.DataRange = "A:F";

% Specify column names and types
opts.VariableNames = ["Time", "PSG", "Garmin", "Fitbit", "Jawbone","Shine"];
opts.VariableTypes = ["double", "double", "double", "double", "double", "double"];

% Import the data
hypnogram_data = readtable(file_path, opts, "UseExcel", false);
hypnogram_data(1:2,:) = [];
clear opts

% Create a figure for the hypnograms

% Define sleep stage mappings for each device
stages = {
    % PSG stages
    {'NaN','Wake', 'REM', 'N1', 'N2', 'N3'},
    % Garmin stages
    {'NaN','Awake', 'Deep', 'Light'},
    % Fitbit stages
    {'NaN','Awake', 'Asleep', 'Restless'},
    % Jawbone stages
    {'NaN','Awake', 'REM', 'Light', 'Deep'},
    % Shine stages (assuming the same as Garmin)
    {'NaN','Awake', 'Deep', 'Light'}
};

num_subplots = length(stages);
figure_height_per_subplot = 200;
figure_width = 800;
figure('Position', [1, 1, figure_width, figure_height_per_subplot * num_subplots]);

% Define the mapping from PSG stages to wearable device stages
psg_to_device_mapping = [0, 0, 0, 0; % NaN
                         1, 1, 1, 1; % Awake
                         3, 3, 2, 3; % REM (no equivalent for some devices)
                         3, 2, 3, 3; % Light Sleep (N1, N2 for PSG)
                         3, 2, 3, 3;  % Light Sleep (N1, N2 for PSG)
                         2, 2, 4, 2]; % Deep Sleep (N3 for PSG)

% Plot hypnogram for each device with PSG benchmark
for i = 1:length(stages)
    subplot(length(stages), 1, i);
    idx = find(hypnogram_data{:, i+1} ~= 0);
    device_stage_values = hypnogram_data{:, i+1};
    device_stage_values(idx) = hypnogram_data{idx, i+1}-10;
    idx = find(hypnogram_data.PSG ~= 0);
    psg_stage_values = hypnogram_data.PSG;
    psg_stage_values(idx) = hypnogram_data.PSG(idx)-10;
 
    
    % Plot the wearable device data

    plot(hypnogram_data.Time, device_stage_values, 'LineWidth', 2);
    hold on;
    if i ~= 1
        % Map PSG stages to current device stages
        for j = 0:size(psg_to_device_mapping, 1)-1
            psg_stage_values(psg_stage_values == j) = psg_to_device_mapping(j+1, i-1);
        end
        % Overlay the mapped PSG data as a benchmarking line
        plot(hypnogram_data.Time, psg_stage_values, 'r--', 'LineWidth', 1.5);  % 'r--' indicates a red dashed line
    end

    ylim([0 length(stages{i})]); % Set the limits of y-axis based on the number of stages
    set(gca, 'ytick', 0:length(stages{i})-1, 'yticklabel', stages{i});
    title(['Hypnogram for ' hypnogram_data.Properties.VariableNames{i+1}]);
    ylabel('Sleep Stage');
    
    % Turn off x-axis labels and ticks for all but the last subplot
    if i < length(stages)
        set(gca, 'XTick', []);
        set(gca, 'XTickLabel', []);
    else
        xlabel('Time');
        datetick('x', 'HH:MM:SS PM', 'keeplimits');
    end
    set(gca,'FontSize',12,'FontWeight','b')
    grid on;
    
    hold off;
end
legend('Device hypnogram','PSG benchmarking')
sgtitle(file_name,'Interpreter','None');

