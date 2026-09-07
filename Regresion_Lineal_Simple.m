%% ============================================================
% REGRESIÓN LINEAL: PRODUCCIÓN SOLAR vs RADIACIÓN
%
% Datos:
%   Radiación Solar (W/m2)
%   Producción Fotovoltaica (W)
%   B0
%   B1
%
% Modelo:
%   Producción = B0 + B1 * Radiacion
%
% ============================================================

clear;
clc;
close all;

set(groot, 'defaultAxesToolbarVisible', 'off');

%% ============================================================
% 1. Selección archivo Excel
% =============================================================

[archivo, ruta] = uigetfile('*.xlsx', 'Seleccione el archivo Excel');

if isequal(archivo, 0)
    disp('No se seleccionó ningún archivo.');
    return;
end

nombreArchivo = fullfile(ruta, archivo);

%% ============================================================
% 2. Lectura datos
% =============================================================

datos = readtable(nombreArchivo);
% Columnas encontradas en el archivo.
% disp(datos.Properties.VariableNames);


%% ============================================================
% 3. Seleccionar columnas
% =============================================================

radiacion = datos.Radiacion_W_m2;
produccion = datos.Produccion_W;

%% ============================================================
% 4. Eliminar datos vacíos o no válidos
% =============================================================

indices = isfinite(radiacion) & isfinite(produccion);
radiacion = radiacion(indices);
produccion = produccion(indices);

%% ============================================================
% 5. Regresión lineal
% =============================================================

% Produccion = B0 + B1 * Radiacion
coef = polyfit(radiacion, produccion, 1);
B1 = coef(1);
B0 = coef(2);  

%% ============================================================
% 6. Calcular producción estimada
% =============================================================

produccion_estimada = polyval(coef, radiacion);

%% ============================================================
% 7. Calcular R²
% =============================================================

SSres = sum((produccion - produccion_estimada).^2);
SStot = sum((produccion - mean(produccion)).^2);
R2 = 1 - SSres/SStot;

%% ============================================================
% 8. Resultados
% =============================================================

fprintf('\n');
fprintf('===================================================\n');
fprintf('REGRESIÓN LINEAL\n');
fprintf('===================================================\n');

fprintf('B0 = %.6f\n', B0);
fprintf('B1 = %.6f\n', B1);
fprintf('R² = %.6f\n', R2);

fprintf('\nEcuación obtenida: P = %.6f + %.6f R\n', B0, B1);

fprintf('===================================================\n');

%% ============================================================
% 9. Gráficas de resultados
% =============================================================

% Crear puntos para dibujar la recta.
radiacion_linea = linspace(min(radiacion), max(radiacion), 100);
produccion_linea = B0 + B1 .* radiacion_linea;

f = figure('Color','w','Name',...
    'Regresión Lineal Simple Producción y Radiación',...
    'Position',[100 100 1100 600]);

% Datos experimentales.
scatter(radiacion, produccion, 40, [0.40 0.75 0.95], 'filled');
hold on;

% Recta de regresión.
plot(radiacion_linea, produccion_linea,'b-', 'LineWidth', 2);

grid on;
box on;

xlabel('Radiación (W/m^2)', 'FontSize', 12);
ylabel('Producción (W)', 'FontSize', 12);
title('Regresión lineal: Producción vs Radiación','FontSize', 14);
xlim([0 1050]);

% Mostrar ecuación y R² dentro de la gráfica
texto = sprintf(['Producción = %.4f + %.4f · Radiación\n' ...
                 'R^2 = %.4f'], B0, B1, R2);

text(0.05, 0.90, texto, 'Units', 'normalized', ...
    'FontSize', 11, 'BackgroundColor', 'white', ...
    'EdgeColor', 'black', 'Margin', 8);

saveas(gcf, 'Regresion_lineal_Produccion_Radiacion.png');

%% ============================================================
% 10. Exportar los resultados a Excel
% =============================================================

resultados = table(radiacion, produccion, produccion_estimada, ...
                   'VariableNames', ...
                   {'Radiacion (W/m2)', ...
                    'Produccion (W)', ...
                    'Produccion Estimada (W)'});

writetable(resultados, 'Resultados_Regresion_Simple.xlsx');

fprintf('\n====================================================\n');
fprintf('RESULTADOS EXPORTADOS\n');
fprintf('====================================================\n');
fprintf('Archivo: Resultados_Regresion_Simple.xlsx\n');
fprintf('Gráfico: Regresion_lineal_Produccion_Radiacion.png\n');



