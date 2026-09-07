%% ============================================================
%  GRÁFICOS DEL DOCUMENTO
% =============================================================

clear;
clc;
close all;
set(groot, 'defaultAxesToolbarVisible', 'off');

%% ============================================================
% 1. EVOLUCIÓN DE LA POTENCIA FOTOVOLTAICA INSTALADA EN ESPAÑA
% =============================================================

% Años evaluados 2006-2025
anio = 2006:2025;

% Potencia Fotovoltaica Instalada en MW
potencia_MW = [...
    125, ... % 2006
    618, ... % 2007
    3351, ... % 2008
    3392, ... % 2009
    3829, ... % 2010
    4233, ... % 2011
    4532, ... % 2012
    4638, ... % 2013
    4646, ... % 2014
    4688.3, ... % 2015
    4693.2, ... % 2016
    4697.7, ... % 2017
    4780.9, ... % 2018
    8789.1, ... % 2019
    12174.1, ... % 2020
    16124.6, ... % 2021
    21804.5, ... % 2022
    29897.4, ... % 2023
    39187.8, ... % 2024
    50342.5]; % 2025

% Convertir de MW a GW
potencia_GW = potencia_MW / 1000;

% Gráfico
f = figure('Name','Evolución de potencia fotovoltaica instalada en España',...
    'Position',[100 100 1100 600], 'Color','w');
b = bar(anio, potencia_GW, 0.75);

% Colores de las barras
b.FaceColor = 'flat';

for i = 1:length(anio)
    if anio(i) >= 2019
        b.CData(i,:) = [0.40 0.75 0.95];   % Azul claro
    else
        b.CData(i,:) = [0.00 0.32 0.60];   % Azul oscuro
    end
end

xlabel('Año','FontSize',12,'FontWeight','bold');
ylabel('Potencia fotovoltaica instalada (GW)', ...
       'FontSize',12,'FontWeight','bold');

title('Evolución de la potencia fotovoltaica instalada en España 2006–2025', ...
      'FontSize',14);

xticks(anio);
xtickangle(45);
xlim([2005.3 2025.7]);
ylim([0 53]);

grid on;
box on;

% Etiquetas de valores
for i = 1:length(anio)
    text(anio(i), potencia_GW(i)+1, sprintf('%.1f',potencia_GW(i)), ...
        'HorizontalAlignment','center','FontSize',8);
end

% Línea vertical para marcar 2019
xline(2018.5,'--', 'Color',[0.3 0.3 0.3],'FontSize',10);

set(gca,'FontSize',10);
exportgraphics(f,'Evolución_Potencia_España.png', 'Resolution', 300);

%% ============================================================
% 2. Coeficiente Spearman
% =============================================================

% Coeficiente Spearman p
P = [ 0.5160, 0.4403, 0, 0, 0 , 0.3761, 0.0657, 0, 0];

% Coeficiente de determinación p2
P2 = P.^2;

categorias = 1:length(P);
datos = [P(:), P2(:)];

f = figure('Color','w','Position',[100 100 1100 600],'Name',...
    'Coeficiente de Spearman (\rho) y coeficiente de determinación (\rho^2)');
b = bar(categorias, datos, 'grouped');

% Colores
b(1).FaceColor = [0.00 0.32 0.60];   % Azul oscuro
b(2).FaceColor = [0.40 0.75 0.95];   % Azul claro

b(1).EdgeColor = [0.00 0.20 0.40];
b(2).EdgeColor = [0.20 0.55 0.75];

grid on;
box on;

xlabel('Variable','FontSize',12,'FontWeight','bold');
ylabel('Coeficiente','FontSize',12,'FontWeight','bold');

title('Coeficiente de Spearman (\rho) y coeficiente de determinación (\rho^2)', ...
      'FontSize',14);

xticks(categorias);
xticklabels({'Temperatura','Vel. Viento','Dir. Viento',...
    'Humedad','Presión','Precipitación','Año','Mes','Día'});
xtickangle(45);
ylim([0 0.6]);

legend({'Spearman (\rho)','Determinación (\rho^2)'}, ...
       'Location','northeast');

% Etiquetas de valores
for i = 1:length(P)
    
    % Spearman
    if P(i) > 0
        text(i-0.15, P(i)+0.015, sprintf('%.3f',P(i)), ...
            'HorizontalAlignment','center', ...
            'FontSize',10);
    end
    
    % R2
    if P2(i) > 0
        text(i+0.15, P2(i)+0.015, sprintf('%.3f',P2(i)), ...
            'HorizontalAlignment','center', ...
            'FontSize',10);
    end
end

exportgraphics(f,'Coeficiente_Spearman_y_Determinacion.png', 'Resolution', 300);

fprintf('\n====================================================\n');
fprintf('RESULTADOS EXPORTADOS\n');
fprintf('====================================================\n');
fprintf('Gráfico Potencia España:Evolución_Potencia_España.png\n');
fprintf('Gráfico Spearman: Coeficiente_Spearman_y_Determinacion.png\n');

