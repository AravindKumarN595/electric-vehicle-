clc; clear; close all;

%% ================= MAIN FIGURE =================
fig = figure('Name','EV Dashboard HMI',...
    'NumberTitle','off',...
    'Color',[0.02 0.02 0.05],...
    'Position',[200 100 1100 650]);

%% ================= SPEEDOMETER PANEL =================
ax1 = axes('Parent',fig,'Position',[0.05 0.15 0.5 0.75]);
axis(ax1,'equal'); axis(ax1,'off'); hold(ax1,'on');

maxSpeed = 120;

% Glow layers (depth effect)
for k = 1:3
    plot(ax1,cos(linspace(pi,0,200)),sin(linspace(pi,0,200)),...
        'Color',[0.1 0.6 1 0.1*k],'LineWidth',6+k);
end

% Color Zones
theta1 = linspace(pi, pi*0.5, 100);
theta2 = linspace(pi*0.5, pi*0.25, 100);
theta3 = linspace(pi*0.25, 0, 100);

plot(ax1,cos(theta1), sin(theta1), 'Color',[0 1 0],'LineWidth',4);
plot(ax1,cos(theta2), sin(theta2), 'Color',[1 0.8 0],'LineWidth',4);
plot(ax1,cos(theta3), sin(theta3), 'Color',[1 0.2 0],'LineWidth',4);

% Tick marks
for s = 0:20:maxSpeed
    angle = pi - (s/maxSpeed)*pi;

    plot(ax1,[0.85*cos(angle) cos(angle)],...
             [0.85*sin(angle) sin(angle)],...
             'Color',[0.8 0.8 0.8],'LineWidth',2);

    text(0.72*cos(angle),0.72*sin(angle),num2str(s),...
        'Color',[0.9 0.9 0.9],'FontSize',11,...
        'HorizontalAlignment','center');
end

% Needle
needle = plot(ax1,[0 0],[0 0.85],...
    'Color',[1 0.1 0.1],'LineWidth',4);

% Center hub
plot(ax1,0,0,'wo','MarkerFaceColor','w','MarkerSize',8);

% Digital speed
speedCenter = text(0,-0.25,'0 km/h',...
    'Color',[0.8 0.9 1],'FontSize',22,...
    'FontWeight','bold',...
    'HorizontalAlignment','center');

title(ax1,'SPEED','Color',[0.7 0.8 1],'FontSize',14);

%% ================= RIGHT PANEL =================
panel = uipanel('Parent',fig,...
    'Position',[0.6 0.1 0.35 0.8],...
    'BackgroundColor',[0.08 0.08 0.12],...
    'Title','Vehicle Status',...
    'ForegroundColor','w',...
    'FontSize',12);

%% ================= BATTERY (CIRCULAR STYLE) =================
ax2 = axes('Parent',panel,'Position',[0.2 0.65 0.6 0.25]);
axis(ax2,'equal'); axis(ax2,'off'); hold(ax2,'on');

theta = linspace(0,2*pi,100);
plot(ax2,cos(theta),sin(theta),'Color',[0.3 0.3 0.3],'LineWidth',6);

batteryArc = plot(ax2,cos(theta),sin(theta),'g','LineWidth',6);

batteryText = text(0,0,'80%',...
    'Color','w','FontSize',16,...
    'HorizontalAlignment','center');

title(ax2,'Battery','Color','w');

%% ================= TEXT INFO =================
powerText = uicontrol(panel,'Style','text',...
    'Units','normalized',...
    'Position',[0.2 0.5 0.6 0.08],...
    'BackgroundColor',[0.08 0.08 0.12],...
    'ForegroundColor','cyan',...
    'FontSize',14,...
    'String','Power: 0 kW');

tempText = uicontrol(panel,'Style','text',...
    'Units','normalized',...
    'Position',[0.2 0.4 0.6 0.08],...
    'BackgroundColor',[0.08 0.08 0.12],...
    'ForegroundColor','yellow',...
    'FontSize',14,...
    'String','Temp: 25 C');

modeBtn = uicontrol(panel,'Style','pushbutton',...
    'Units','normalized',...
    'Position',[0.2 0.25 0.6 0.1],...
    'String','Mode: ECO',...
    'FontSize',13,...
    'BackgroundColor',[0.2 0.2 0.3],...
    'ForegroundColor','w',...
    'Callback',@changeMode);

btText = uicontrol(panel,'Style','text',...
    'Units','normalized',...
    'Position',[0.1 0.05 0.8 0.1],...
    'BackgroundColor',[0 0 0],...
    'ForegroundColor','green',...
    'FontSize',11,...
    'FontWeight','bold',...
    'String','BT Msg: ---');

%% ================= BLUETOOTH =================
bt = serialport("COM5",9600);
configureTerminator(bt,"LF");

%% ================= SIMULATION =================
speed = 0;
battery = 80;

for t = 1:600

    speed = max(0,min(maxSpeed,speed + randn*2));
    battery = max(0,battery - 0.01*speed/50);
    power = speed*0.5;
    temp = 25 + speed*0.2;

    % Needle
    angle = pi - (speed/maxSpeed)*pi;
    set(needle,'XData',[0 0.85*cos(angle)],...
               'YData',[0 0.85*sin(angle)]);

    % Speed text
    set(speedCenter,'String',sprintf('%d km/h',round(speed)));

    % Battery circular update
    thetaBat = linspace(0,2*pi*(battery/100),100);
    set(batteryArc,'XData',cos(thetaBat),'YData',sin(thetaBat));

    set(batteryText,'String',sprintf('%d%%',round(battery)));

    % Color logic
    if battery > 60
        batteryArc.Color = 'g';
    elseif battery > 30
        batteryArc.Color = 'y';
    else
        batteryArc.Color = 'r';
    end

    % Text update
    set(powerText,'String',sprintf('Power: %.1f kW',power));
    set(tempText,'String',sprintf('Temp: %.1f C',temp));

    % Bluetooth receive
    if bt.NumBytesAvailable > 0
        msg = strtrim(readline(bt));
        set(btText,'String',['BT Msg: ' msg]);

        if strcmpi(msg,'ECO')
            modeBtn.String = 'Mode: ECO';
        elseif strcmpi(msg,'NORMAL')
            modeBtn.String = 'Mode: NORMAL';
        elseif strcmpi(msg,'SPORT')
            modeBtn.String = 'Mode: SPORT';
        end
    end

    % Send data
    writeline(bt,sprintf("Speed:%d Temp:%.1f\n",round(speed),temp));

    drawnow;
    pause(0.05);
end

clear bt;

%% ================= MODE FUNCTION =================
function changeMode(src,~)
    if contains(src.String,'ECO')
        src.String = 'Mode: NORMAL';
    elseif contains(src.String,'NORMAL')
        src.String = 'Mode: SPORT';
    else
        src.String = 'Mode: ECO';
    end
end
