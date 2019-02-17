clear all; close all; clc
%% Read in and process initial mass and time data
prompt = 'Enter Date (YYMMDD): '; % prompt user for time data
mousePrompt = 'Enter Mouse Number (##): ';
file = input(prompt, 's');
mouseNumber = input(mousePrompt, 's');
weight = csvread(strcat(file, '_', mouseNumber, 'LOADCELL.CSV'));
fid = fopen(strcat(file, '_', mouseNumber, 'TIME.CSV'));
A=textscan(fid,'%8s');
dn=datenum(A{1},'HH:MM:SS');
if (size(weight, 1) ~= size(dn, 1))                             % if the dimensions are not the same, modify the time data
    dn = dn(1:end - 1);
end

index = 1;                                                
difference = 10;
while weight(index) < 0.02 || abs(difference) > 0.02            % cut off initial data
    difference = weight(index + 1) - weight(index);
    index = index + 1;
end
dn = dn(index : end);
weight = weight(index : end);

n = zeros(size(weight));
for i = 1 : size(n)
    n(i) = i / 30 / 60;
end

%% Plot raw consumption data
figure(1)
plot(n, weight, 'o');
title('Gel Consumption', 'FontSize', 18);
ylabel('Mass (g)', 'FontSize', 16);
xlabel('Time', 'FontSize', 16);
legend('Mass of Gel in Cup', 'Location', 'SouthEast');

%% max out distinct eating events
newWeight = weight;                                             % new vector for thresholded data  
cap = 20;                                                       % arbitrary maximum value to set thresholded data to
for i = 1 : size(weight) - 1                                    % parse through weight vector
    diff = weight(i + 1) - weight(i);                           % compare data at each index with the next one
    if abs(diff) > 0.04 || weight(i) > cap                      % if data points are unstable, max out data
        newWeight(i + 1) = cap;
    else
        newWeight(i) = weight(i);                               % if data is stable, keep original weight data
    end 
end

%% Plot new processed data
figure(2)
fig = plot(n, newWeight,'ko');
title('Gel Consumption Adjusted (Relative Time)', 'FontSize', 18)
ylim([-5 cap + 5])
ylabel('Mass (g)', 'FontSize', 16)
xlabel('Time (hours)', 'FontSize', 16)
legend(strcat('Mouse Number: ', mouseNumber), 'Location', 'SouthEast')
saveas(fig, strcat(file, '_', mouseNumber, 'ProcessedData.jpg'))
figure(2)
plot(n, newWeight,'ko')
title('Gel Consumption Adjusted (Relative Time)', 'FontSize', 18)
ylim([-5 cap + 5])
ylabel('Mass (g)', 'FontSize', 16)
xlabel('Time (hours)', 'FontSize', 16)
legend('Mass of Gel in Cup', 'Location', 'SouthEast')

%% Separating Data
n = n(300 : end);
newWeight = newWeight(300 : end);                         % Clip new data
inc = 1;
while newWeight(1) == 20                                  % Eliminate any non-mass readings
   newWeight = newWeight(2 : end);
   n = n(2 : end);
end
eatingEvents = zeros(size(newWeight));
massData = zeros(size(newWeight));
for i = 1 : size(newWeight)                               % Loop through and classify each point as an eating event or 
                                                          % a mass value
    if newWeight(i) > 19.9  || newWeight(i) < 0
        if i > 1
            eatingEvents(i) = 1;
            massData(i) = massData(i - 1);
        end
    else
        massData(i) = newWeight(i);
    end
end
massData = massData(1) - massData;                       % Change the data to reflect mass consumed instead of mass remaining
for i = 1 : size(massData)                               
   if massData(i) < 0 && i ~= 1
      massData(i) = massData(i - 1); 
   end
end
testMassData = massData;
for i = 1 : size(testMassData)                          % Account for gel dessication rate
    testMassData(i) = testMassData(i) - ((1.06 * 10 ^ -5) * 2 * i);
end
windowSize = 500;                                       % Smooth the resulting mass curves
b = (1/windowSize)*ones(1,windowSize);
a = 1;
massData = filter(b, a, massData);

figure(4)
subplot(2,1,1)
plot(n, massData, 'ko', 'MarkerSize', 3);
title('Mass of Gel Consumed', 'FontSize', 18)
ylabel('Mass of gel (g)')
xlabel('Time (hours)')

subplot(2,1,2)
plot(n, eatingEvents, 'ko');
ylim([0.99 1.1]);
title('Eating Events', 'FontSize', 18)
xlabel('Time (hours)');

%% Create distribution of inter-eating intervals
binsize = 5;             %<----------------------------- size of bins
 
threshold = 120;         %<-- time in seconds between events required to consider distinct eating event

bouttimes = [];
endEvent= 0;
bouts = [];
for i = 1 : size(eatingEvents)                    % Count the number of bouts and stamp when they occur
    if (eatingEvents(i) == 1)
        diff = n(i) - endEvent;
        if (diff * 3600 >= threshold)
           bouts = [bouts; endEvent diff * 60];
        end
        endEvent = n(i);
        bouttimes = [bouttimes; diff];
    end
end
bouttimes = bouttimes * 3600;
bins = 0 : binsize : max(bouttimes);
bins =[zeros(size(bins)); bins];
bouts
xlswrite(strcat(file, '_', mouseNumber, 'boutData.xlsx'), bouts(:,1))
numberOfBouts = size(bouts,1)

% Plot frequency distribution of inter-eating intervals
figure(5)
histogram(bouttimes, size(bins,2))
ylim([0 50])
xlim([0 250])
xlabel('Inter-eating interval (sec)', 'FontSize', 14)
ylabel('Number of intervals', 'FontSize', 14)
title('Frequency Distribution of Inter-eating Intervals','FontSize', 18)

%% Plot duration of eating bouts and cup disturbances
figure(6)
plot(bouts(:, 1), bouts(:,2), 'bo', 'MarkerSize', 4)
hold on
plot(n, eatingEvents * 60, 'ko', 'MarkerSize', 4)
xlabel('Time (hours)')
ylabel('Duration of Inter-Eating Interval for Bouts Only (minutes)')
title('Distribution of eating bouts', 'FontSize', 18)
legend('Eating bouts', 'Gel Cup Disturbances', 'Location', 'NorthEast')


%% Correlating Change in Mass with Number of Eating Events
slopes =[];
distEatingEvents = [];
for i = 1 : 150 : size(massData) - 150
    total = 0;
    for j = 0 : 150
       total = (massData(i + j + 1) - massData(i + j)) / 2 + total;
    end
    dydx = total / 150;
    slopes = [slopes; dydx];
    countEat = 0;
    for j = 0 : 150
        if eatingEvents(i + j) == 1
            countEat = countEat + 1;
        end
    end
    distEatingEvents = [distEatingEvents; countEat];
end
model = fitlm(distEatingEvents, slopes)

pcoeff = polyfit(distEatingEvents, slopes, 1);
t = 0:0.1:60;
vals = polyval(pcoeff, t);

figure(7)
plot(distEatingEvents, slopes, 'ko', 'MarkerSize', 6)
title('Correlation of Eating Events and Gel Consumption', 'FontSize', 22)
xlabel('Eating Events in 5 Minute Period', 'FontSize', 18)
ylabel('Average Gel Consumption in 5 Minute Period (g/sec)', 'FontSize', 18)
hold on
plot(t, vals, 'r-', 'LineWidth', 2)
legend('Correlation', 'Linear Regression Line')
text(50, 2*10^-4, ['R^2 = ' num2str(model.Rsquared.Adjusted)], 'FontSize', 16)
text(50, 0*10^-4, ['p = ' num2str(model.Coefficients{2,4})], 'FontSize', 16)

%% Save processed Data to a File
endPrompt = 'Would you like to save the data? (y or n) : ';
if (input(endPrompt, 's') == 'y')
   xlswrite(strcat(file, '_', mouseNumber, 'loadcellData.xlsx'), massData);
end
    