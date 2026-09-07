%% ============================================================
% ESTIMACIÓN DE PRODUCCIÓN FOTOVOLTAICA MEDIANTE RED NEURONAL
% CON VALORACÓN SEGUN CONDICIÓN CLIMATOLÓGICA
%
% Datos:
%   2020, 2021 y 2022
%   Sin datos nocturnos
%   Normalización MIN-MAX AJUSTTADA
%   Xnorm = 0.8*((X-Xmin)/(Xmax-Xmin)) + 0.1
%
% Inputs Modelo X:
%   1. Día
%   2. Mes
%   3. Hora
%   4. Radiación solar
%   5. Temperatura del aire
%   6. Velocidad del viento
%   7. Dirección del viento
%   8. Humedad
%   9. Presión Atmosférica
%   10. Precipitación
%
% Target:
%   1. Producción solar
%
% División:
%   70 % Entrenamiento
%   15 % Validación
%   15 % Test
%
% Valoraciones:
%   Lluvia (precipitación > 0)
%   No lluvia (precipitación = 0)
%   Radiación baja (< P25)
%   Radiación media (P25 - P75)
%   Radiación alta (> P75)
%
% ============================================================

clear;
clc;
close all;

% Quitar toolbox de gráfico para exportar sin ello.
set(groot, 'defaultAxesToolbarVisible', 'off');

%% ============================================================
%  Valores normalización
% =============================================================

% Producción.
Pmin = 0.0021;    
Pmax = 7488.9041; 

% Radiación.
RadiacionMin = 0;
RadiacionMax = 1045;

% Precipitación.
PrecipMin = 0;
PrecipMax = 19.8;


%% ============================================================
% 1. FIJAR SEMILLA ALEATORIA
% =============================================================

% Permite que todas las redes utilicen exactamente
% la misma división de datos.
rng(1);

%% ============================================================
%  2. SELECCIÓN Y LECTURA DE INPUT Y TARGET
%  ============================================================

% Input = Datos clima
[archivo, ruta] = uigetfile('*.xlsx',...
    'Seleccione el archivo de datos metereológicos.');

if isequal(archivo, 0)
    disp('No seleccionó ningún archivo.');
    return;
end

nombreArchivo = fullfile(ruta, archivo);

input = readmatrix(nombreArchivo);
input = input.';

% Target = Producción solar
[archivo, ruta] = uigetfile('*.xlsx',...
    'Seleccione el archivo de datos de producción.');

if isequal(archivo, 0)
    disp('No seleccionó ningún archivo.');
    return;
end

nombreArchivo = fullfile(ruta, archivo);

target = readmatrix(nombreArchivo);
target = target.';

%% ============================================================
% 3. COMPROBACIÓN DATOS
% =============================================================

% Comprobación de que el número de muestras coincide.
if size(input,2) ~= size(target,2)
        error(['El número de muestras de INPUT y TARGET no coincide. ', ...
           'Compruebe ambos archivos.']);
end

% Comprobación valores nulos.
if any(isnan(input(:))) || any(isnan(target(:)))
    error(['Existen valores nulos en los datos. ', ...
           'Es necesario eliminarlos antes del entrenamiento.']);
end

%% ============================================================
% 4. CREACIÓN DE UNA ÚNICA DIVISIÓN DE DATOS
% =============================================================

N = size(input,2);

% Índices aleatorios con permutación aleatoria.
indices = randperm(N);

% Número de muestras para cada conjunto.
N_train = round(0.70*N);
N_val = round(0.15*N);

% Índices
idx_train = indices(1:N_train);
idx_val = indices(N_train+1:N_train+N_val);
idx_test = indices(N_train+N_val+1:end);

fprintf('\n=============================================\n');
fprintf('DIVISIÓN DE LOS DATOS\n');
fprintf('=============================================\n');

fprintf('Entrenamiento  = %d muestras (%.2f %%)\n', ...
    length(idx_train),100*length(idx_train)/N);
fprintf('Validación     = %d muestras (%.2f %%)\n', ...
    length(idx_val),100*length(idx_val)/N);
fprintf('Test           = %d muestras (%.2f %%)\n', ...
    length(idx_test),100*length(idx_test)/N);


%% ============================================================
% 5. SELECCIÓN DE ARQUITECTURAS A PROBAR
% =============================================================

% Número de neuronas de la capa oculta.
% Se prueban redes desde 1 hasta 50 neuronas.
neuronas = 1:50;
numModelos = length(neuronas);


%% ============================================================
% 6. CREACIÓN DE LA MATRIZ PARA GUARDAR RESULTADOS
% =============================================================

% Columnas:
% 1     Neuronas
% 2-8   Entrenamiento
% 9-15  Validación
% 16-22 Test

resultados = zeros(numModelos,22);

%% ============================================================
% 7. ENTRENAMIENTO DE TODAS LAS ARQUITECTURAS
% =============================================================

fprintf('\n=============================================\n');
fprintf('INICIO\n');
fprintf('=============================================');

for i = 1:numModelos

    fprintf('\nProbando %d neuronas.',neuronas(i));

    % --------------------------------------------------------
    % Creación de la red
    % ---------------------------------------------------------
    % 'trainlm' Levenberg-Marquardt (+ rápida)
    % 'trainbr' Regularización bayesiana
    % 'trainbfg' BFGS quasi-Newton
    % 'trainrp' Retropropagación resiliente
    % 'traingd' Gradiente descendente

    net = feedforwardnet(neuronas(i),'trainlm');

    % --------------------------------------------------------
    % Configuración de la división
    % ---------------------------------------------------------

    % Se utilizan índices previamente definidos.
    % Así todas las redes utilizan exactamente los mismos
    % datos de entrenamiento, validación y test.
    net.divideFcn = 'divideind';
    net.divideParam.trainInd = idx_train;
    net.divideParam.valInd = idx_val;
    net.divideParam.testInd = idx_test;

    % --------------------------------------------------------
    % Entrenamiento de la red
    % ---------------------------------------------------------

    [net,tr] = train(net,input,target);

    % --------------------------------------------------------
    % Estimación
    % ---------------------------------------------------------

    % Salida de la red normalizada.
    output = net(input);

    % ========================================================
    % ENTRENAMIENTO
    % ========================================================

    y_real_norm = target(idx_train);
    y_pred_norm = output(idx_train);

    % Desnormalizar.
    y_real = desnormalizarMinMaxAjustado(y_real_norm,Pmin,Pmax);
    y_pred = desnormalizarMinMaxAjustado(y_pred_norm,Pmin,Pmax);

    % Métricas.
    [MSE,RMSE,nRMSE,MAE,MAPE,r,R2] = calcularMetricas(y_real,y_pred,Pmin,Pmax);

    resultados(i,1) = neuronas(i);

    resultados(i,2) = MSE;
    resultados(i,3) = RMSE;
    resultados(i,4) = nRMSE;
    resultados(i,5) = MAE;
    resultados(i,6) = MAPE;
    resultados(i,7) = r;
    resultados(i,8) = R2;

    % ========================================================
    % VALIDACIÓN
    % ========================================================

    y_real_norm = target(idx_val);
    y_pred_norm = output(idx_val);

    % Desnormalizar.
    y_real = desnormalizarMinMaxAjustado(y_real_norm,Pmin,Pmax);
    y_pred = desnormalizarMinMaxAjustado(y_pred_norm,Pmin,Pmax);

    % Calcular métricas.
    [MSE,RMSE,nRMSE,MAE,MAPE,r,R2] = calcularMetricas(y_real,y_pred,Pmin,Pmax);

    resultados(i,9)  = MSE;
    resultados(i,10) = RMSE;
    resultados(i,11) = nRMSE;
    resultados(i,12) = MAE;
    resultados(i,13) = MAPE;
    resultados(i,14) = r;
    resultados(i,15) = R2;

    % ========================================================
    % TEST
    % ========================================================

    y_real_norm = target(idx_test);
    y_pred_norm = output(idx_test);

    % Desnormalizar.
    y_real = desnormalizarMinMaxAjustado(y_real_norm,Pmin,Pmax);
    y_pred = desnormalizarMinMaxAjustado(y_pred_norm,Pmin,Pmax);

    % Métricas.
    [MSE,RMSE,nRMSE,MAE,MAPE,r,R2] = calcularMetricas(y_real,y_pred,Pmin,Pmax);

    resultados(i,16) = MSE;
    resultados(i,17) = RMSE;
    resultados(i,18) = nRMSE;
    resultados(i,19) = MAE;
    resultados(i,20) = MAPE;
    resultados(i,21) = r;
    resultados(i,22) = R2;

    % Resultados de validación.
    % fprintf(['\nRMSE validación = %.6f | ', ...
    %     'nRMSE = %.2f %% | ','MAE = %.6f | ', ...
    %     'MAPE = %.2f %% | ','r = %.6f | ', ...
    %     'R2 = %.6f\n'], resultados(i,10),resultados(i,11), ...
    %     resultados(i,12),resultados(i,13), ...
    %     resultados(i,14), resultados(i,15));
end


%% ============================================================
% 8. CREACIÓN DE TABLA DE RESULTADOS
% =============================================================

TablaResultados = table( ...
    resultados(:,1), resultados(:,2),resultados(:,3), ...
    resultados(:,4), resultados(:,5),resultados(:,6), ...
    resultados(:,7), resultados(:,8),resultados(:,9), ...
    resultados(:,10), resultados(:,11),resultados(:,12), ...
    resultados(:,13),resultados(:,14),resultados(:,15), ...
    resultados(:,16),resultados(:,17),resultados(:,18), ...
    resultados(:,19),resultados(:,20),resultados(:,21), ...
    resultados(:,22), 'VariableNames', ...
    {'Neuronas','MSE_Train','RMSE_Train', ...
    'nRMSE_Train','MAE_Train','MAPE_Train','r_Train', ...
    'R2_Train','MSE_Val','RMSE_Val','nRMSE_Val','MAE_Val', ...
    'MAPE_Val','r_Val','R2_Val','MSE_Test','RMSE_Test', ...
    'nRMSE_Test','MAE_Test','MAPE_Test','r_Test','R2_Test'});

%% ============================================================
% 9. MOSTRAR TABLA DE RESULTADOS
% ============================================================

fprintf('\n\n');
fprintf('=============================================\n');
fprintf('RESULTADOS DE TODAS LAS ARQUITECTURAS\n');
fprintf('=============================================\n\n');

disp(TablaResultados);

%% ============================================================
% 10. SELECCIÓN DE LA MEJOR ARQUITECTURA
% =============================================================

% Se selecciona la arquitectura que obtiene el menor
% RMSE en el conjunto de VALIDACIÓN.

[~,indiceMejor] = min(resultados(:,10));
mejorNeurona = neuronas(indiceMejor);

fprintf('\n');
fprintf('=============================================\n');
fprintf('MEJOR ARQUITECTURA\n');
fprintf('=============================================\n');

fprintf('Neuronas         = %d\n',mejorNeurona);
fprintf('RMSE validación  = %.6f\n',resultados(indiceMejor,10));
fprintf('nRMSE validación = %.2f%%\n',resultados(indiceMejor,11));
fprintf('MAE validación   = %.6f\n',resultados(indiceMejor,12));
fprintf('MAPE validación  = %.2f%%\n',resultados(indiceMejor,13));
fprintf('r validación     = %.6f\n',resultados(indiceMejor,14));
fprintf('R2 validación    = %.6f\n',resultados(indiceMejor,15));

%% ============================================================
% 11. ENTRENAMIENTO DE NUEVO DE LA MEJOR ARQUITECTURA
% =============================================================

net = feedforwardnet(mejorNeurona,'trainlm');

% Misma división.
net.divideFcn = 'divideind';
net.divideParam.trainInd = idx_train;
net.divideParam.valInd = idx_val;
net.divideParam.testInd = idx_test;

% Entrenamiento.
[net,tr] = train(net,input,target);

% Estimación.
output = net(input);

%% ============================================================
% 12. MÉTRICAS FINALES DEL TEST
% =============================================================

% Valores normalizados.
y_test_real_norm = target(idx_test);
y_test_pred_norm = output(idx_test);

% Desnormalizar.
y_test_real = desnormalizarMinMaxAjustado(y_test_real_norm,Pmin,Pmax);
y_test_pred = desnormalizarMinMaxAjustado(y_test_pred_norm,Pmin,Pmax);

% ------------------------------------------------------------
% CALCULAR MÉTRICAS EN ESCALA ORIGINAL
% ------------------------------------------------------------

[MSE_test,RMSE_test,nRMSE_test,MAE_test, ...
    MAPE_test,r_test,R2_test] = ...
    calcularMetricas(y_test_real,y_test_pred,Pmin,Pmax);

%% ============================================================
%  14. RESULTADOS FINALES
%  ============================================================

fprintf('\n=============================================\n');
fprintf('RESULTADOS FINALES - CONJUNTO TEST\n');
fprintf('=============================================\n');

fprintf('Neuronas = %d\n',mejorNeurona);
fprintf('MSE      = %.6f\n',MSE_test);
fprintf('RMSE     = %.6f\n',RMSE_test);
fprintf('nRMSE    = %.2f%%\n',nRMSE_test);
fprintf('MAE      = %.6f\n',MAE_test);
fprintf('MAPE     = %.2f%%\n',MAPE_test);
fprintf('r        = %.6f\n',r_test);
fprintf('R2       = %.6f\n',R2_test);

%% ============================================================
%  14. EVALUACIÓN DEL RENDIMIENTO CONDICIONES METEOROLÓGICAS
%  ============================================================

% ------------------------------------------------------------
% ÍNDICES DE INPUTS
% ------------------------------------------------------------
IDX_DIA        = 1;
IDX_MES        = 2;
IDX_HORA       = 3;
IDX_RADIACION  = 4;
IDX_TEMP       = 5;
IDX_VIENTO     = 6;
IDX_DIRVIENTO  = 7;
IDX_HUMEDAD    = 8;
IDX_PRESION    = 9;
IDX_PRECIP     = 10;

% ------------------------------------------------------------
% RECUPERAR VARIABLES METEOROLÓGICAS EN ESCALA ORIGINAL
% ------------------------------------------------------------

radiacion_test = desnormalizarMinMaxAjustado( ...
    input(IDX_RADIACION,idx_test), RadiacionMin,RadiacionMax);

precipitacion_test = desnormalizarMinMaxAjustado( ...
    input(IDX_PRECIP,idx_test), PrecipMin,PrecipMax);

% ------------------------------------------------------------
% CONDICIÓN DE LLUVIA
% ------------------------------------------------------------

idx_lluvia = precipitacion_test > 0;
idx_sin_lluvia = precipitacion_test <= 0;

% ------------------------------------------------------------
% CONDICIONES SEGÚN RADIACIÓN
% ------------------------------------------------------------

umbral_baja = prctile(radiacion_test,25);
umbral_alta = prctile(radiacion_test,75);

% Baja radiación.
idx_baja_radiacion = radiacion_test <= umbral_baja;

% Radiación intermedia.
idx_radiacion_intermedia = radiacion_test > umbral_baja & ...
    radiacion_test < umbral_alta;

% Alta radiación.
idx_alta_radiacion = radiacion_test >= umbral_alta;

% ------------------------------------------------------------
% EVALUACIÓN DE CADA CONDICIÓN
% ------------------------------------------------------------

[N_lluvia,MSE_lluvia,RMSE_lluvia,nRMSE_lluvia, ...
    MAE_lluvia,MAPE_lluvia,r_lluvia,R2_lluvia] = evaluarCondicion( ...
    y_test_real,y_test_pred,idx_lluvia,Pmin,Pmax);


[N_sin_lluvia,MSE_sin_lluvia,RMSE_sin_lluvia,nRMSE_sin_lluvia, ...
    MAE_sin_lluvia,MAPE_sin_lluvia,r_sin_lluvia,R2_sin_lluvia] = ...
    evaluarCondicion(y_test_real,y_test_pred,idx_sin_lluvia,Pmin,Pmax);


[N_baja,MSE_baja,RMSE_baja,nRMSE_baja, ...
    MAE_baja,MAPE_baja,r_baja,R2_baja] = evaluarCondicion( ...
    y_test_real,y_test_pred,idx_baja_radiacion,Pmin,Pmax);


[N_intermedia,MSE_intermedia,RMSE_intermedia,nRMSE_intermedia, ...
    MAE_intermedia,MAPE_intermedia,r_intermedia,R2_intermedia] = ...
    evaluarCondicion(y_test_real,y_test_pred,idx_radiacion_intermedia,Pmin,Pmax);


[N_alta,MSE_alta,RMSE_alta,nRMSE_alta, ...
    MAE_alta,MAPE_alta,r_alta,R2_alta] = evaluarCondicion( ...
    y_test_real,y_test_pred,idx_alta_radiacion,Pmin,Pmax);

% ------------------------------------------------------------
% TABLA DE RENDIMIENTO SEGÚN CONDICIÓN
% ------------------------------------------------------------

Condicion = {
    'Lluvia'
    'Sin lluvia'
    'Radiación baja'
    'Radiación intermedia'
    'Radiacion alta'
    };

N = [
    N_lluvia
    N_sin_lluvia
    N_baja
    N_intermedia
    N_alta
    ];

MSE = [
    MSE_lluvia
    MSE_sin_lluvia
    MSE_baja
    MSE_intermedia
    MSE_alta
    ];

RMSE = [
    RMSE_lluvia
    RMSE_sin_lluvia
    RMSE_baja
    RMSE_intermedia
    RMSE_alta
    ];

nRMSE = [
    nRMSE_lluvia
    nRMSE_sin_lluvia
    nRMSE_baja
    nRMSE_intermedia
    nRMSE_alta
    ];

MAE = [
    MAE_lluvia
    MAE_sin_lluvia
    MAE_baja
    MAE_intermedia
    MAE_alta
    ];

MAPE = [
    MAPE_lluvia
    MAPE_sin_lluvia
    MAPE_baja
    MAPE_intermedia
    MAPE_alta
    ];

r = [
    r_lluvia
    r_sin_lluvia
    r_baja
    r_intermedia
    r_alta
    ];

R2 = [
    R2_lluvia
    R2_sin_lluvia
    R2_baja
    R2_intermedia
    R2_alta
    ];

ResultadosCondiciones = table(Condicion,N,MSE,RMSE,nRMSE,MAE,MAPE,r,R2);

fprintf('\n');
fprintf('=============================================\n');
fprintf('RENDIMIENTO SEGÚN CONDICIONES METEOROLÓGICAS\n');
fprintf('=============================================\n\n');

disp(ResultadosCondiciones);

%% ============================================================
%  15. REGRESIÓN DEL CONJUNTO TEST
%  ============================================================

f = figure('Name','Regresión [Test]', 'Position',[100 100 1100 600],...
    'Color','w');
plotregression(y_test_real,y_test_pred);
title(sprintf('Regresión (%d Neuronas) [Test]',mejorNeurona));

exportgraphics(f, 'RegresiónTest.png', 'Resolution', 300);


%% ============================================================
% 16. DISPERSIÓN REAL VS ESTIMADA
% =============================================================

f = figure('Name','Dispersión Real vs Estimada','Color','w');

scatter(y_test_real,y_test_pred,15,'filled',...
    'MarkerFaceColor',[0.40 0.75 0.95]);
hold on;

% Línea ideal y=x.
limites = [min([y_test_real(:);y_test_pred(:)]), ...
    max([y_test_real(:);y_test_pred(:)])];
plot(limites,limites,'LineWidth',1.5, 'Color',[0.00 0.32 0.60]);
grid on;

xlabel('Producción real (W)');
xlim([0,7000]);
ylabel('Producción estimada (W)');
title(sprintf('Producción real vs estimada (R^2 = %.4f) [Test]',R2_test));
legend('Datos', 'Estimación ideal y=x','Location','best');

exportgraphics(f,'Dispersion_Real_vs_Estimada.png', 'Resolution', 300);

%% ============================================================
% 17. RMSE DE VALIDACIÓN VS NEURONAS
% =============================================================

f = figure('Name','RMSE [Validación]','Position',[100 100 1100 600],...
    'Color','w');

plot(neuronas,resultados(:,10),'o-','LineWidth',1.5,'MarkerSize',5, ...
     'Color', [0.00 0.32 0.60]);
hold on;
plot(mejorNeurona,resultados(indiceMejor,10),'o','MarkerSize', 10,...
    'Color', [0.40 0.75 0.95], 'LineWidth',2);
grid on;

xlabel('Neuronas');
ylabel('RMSE (W)');
title('RMSE [Validación]');
legend('RMSE Validación','Mejor arquitectura','Location','best');

exportgraphics(f,'RMSE_Validacion.png', 'Resolution', 300);

%% ============================================================
% 18. R2 DE VALIDACIÓN VS NEURONAS
% =============================================================

f = figure('Name','R2 [Validación]','Position',[100 100 1100 600],...
    'Color','w');

plot(neuronas,resultados(:,15),'o-','LineWidth',1.5,'MarkerSize',5,...
    'Color', [0.00 0.32 0.60]);
hold on;
plot( mejorNeurona,resultados(indiceMejor,15),'o','MarkerSize',10,...
    'Color', [0.40 0.75 0.95], 'LineWidth',2);
grid on;

xlabel('Neuronas');
ylabel('R^2');
title(['Coeficiente de determinación R^2 [Validación]']);
legend('R^2 de validación','Mejor arquitectura','Location','best');

exportgraphics(f,'R2_Validacion.png', 'Resolution', 300);

%% ============================================================
% 19. nRMSE SEGÚN CONDICIÓN METEOROLÓGICA
% =============================================================

f = figure('Name','RMSE según condición meteorológica',...
    'Position',[100 100 1100 600], 'Color','w');

bar(ResultadosCondiciones.RMSE, 'FaceColor', [0.40 0.75 0.95]);
grid on;

xticklabels(ResultadosCondiciones.Condicion);
ylabel('RMSE (W)');
xlabel('Condición meteorológica');
title(sprintf('RMSE según condición meteorológica (%d neuronas)', ...
    mejorNeurona));

exportgraphics( f,'RMSE_Condiciones_Meteorologicas.png','Resolution',300);

%% ============================================================
% 20. R2 SEGÚN CONDICIÓN METEOROLÓGICA
% =============================================================

f = figure('Name','R2 según condición meteorológica',...
    'Position',[100 100 1100 600], 'Color','w');

bar(ResultadosCondiciones.R2, 'FaceColor', [0.40 0.75 0.95]);
grid on;

xticklabels(ResultadosCondiciones.Condicion);
ylabel('R^2');
xlabel('Condición meteorológica');
title(sprintf('R^2 según condición meteorológica (%d neuronas)',...
    mejorNeurona));

exportgraphics(f, 'R2_Condiciones_Meteorologicas.png', 'Resolution',300);

%% ============================================================
%  21. EXPORTACIÓN DE RESULTADOS A EXCEL
%  ============================================================

writetable(TablaResultados, 'resultados.xlsx');
writetable(ResultadosCondiciones,'resultados_condiciones.xlsx');

fprintf('\n=============================================\n');
fprintf('RESULTADOS EXPORTADOS\n');
fprintf('=============================================\n');
fprintf('Archivo: resultados.xlsx\n');
fprintf('Archivo evaluación condiciones: resultados_condiciones.xlsx\n');


%% ============================================================
%  FUNCIÓN DESNORMALIZACIÓN MIN-MAX AJUSTADA
%  ============================================================

function x_original = desnormalizarMinMaxAjustado(x_normalizado,Xmin,Xmax)

    % --------------------------------------------------------
    % Normalización utilizada:
    % Xnorm = 0.8*((X-Xmin)/(Xmax-Xmin))+0.1
    % Desnormalización:
    % X = ((Xnorm-0.1)/0.8)*(Xmax-Xmin)+Xmin
    % --------------------------------------------------------

    x_original = ((x_normalizado-0.1)/0.8)*(Xmax-Xmin)+Xmin;

end

%% ============================================================
%  FUNCIÓN CÁLCULO MÉTRICAS
%  ============================================================

function [MSE,RMSE,nRMSE,MAE,MAPE,r,R2] = ...
    calcularMetricas(y_real,y_pred,Pmin,Pmax)

    % Convertir a vectores columna.
    y_real = y_real(:);
    y_pred = y_pred(:);

    % Eliminar nulos.
    idx = ~isnan(y_real) & ~isnan(y_pred);
    y_real = y_real(idx);
    y_pred = y_pred(idx);

    % Error.
    error = y_real-y_pred;

    % MSE.
    MSE = mean(error.^2);

    % RMSE.
    RMSE = sqrt(MSE);

    % nRMSE.
    if Pmax > Pmin
        nRMSE = RMSE/(Pmax-Pmin)*100;
    else
        nRMSE = NaN;
    end

    % MAE.
    MAE = mean(abs(error));

    % MAPE.
    % Eliminar  valores reales = 0 para evitar división entre cero.
    idx_mape = y_real ~= 0;

    if any(idx_mape)
        MAPE = mean(abs(error(idx_mape)./y_real(idx_mape)))*100;
    else
        MAPE = NaN;
    end

    % Coeficiente de correlación r.
    if length(y_real) > 1
        matrizR = corrcoef(y_real,y_pred);
        r = matrizR(1,2);
    else
        r = NaN;
    end

    % Coeficiente de determinación R2.
    SSE = sum((y_real-y_pred).^2);
    SST = sum((y_real-mean(y_real)).^2);

    if SST > 0
        R2 = 1-SSE/SST;
    else
        R2 = NaN;
    end
end

%% ============================================================
%  FUNCIÓN EVALUAR CONDICIONES
%  ============================================================

function [N,MSE,RMSE,nRMSE,MAE,MAPE,r,R2] = ...
    evaluarCondicion(y_real,y_pred,indices,Pmin,Pmax)

    y_real_cond = y_real(indices);
    y_pred_cond = y_pred(indices);

    N = length(y_real_cond);

    if N > 0
        [MSE,RMSE,nRMSE,MAE,MAPE,r,R2] = calcularMetricas( ...
            y_real_cond,y_pred_cond, Pmin,Pmax);
    else
        MSE = NaN;
        RMSE = NaN;
        nRMSE = NaN;
        MAE = NaN;
        MAPE = NaN;
        r = NaN;
        R2 = NaN;
    end
end


