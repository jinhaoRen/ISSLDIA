function [psnr,sam,ergas,uiqi,ssim] = run_comparison(conf,upscaling)
% The results are written into HTML report, together with thumbnails
addpath('quality');
if ~isfield(conf,'countedtime')
    conf.countedtime = zeros(numel(conf.filenames),numel(conf.results{1}))';
end

qmkdir([conf.result_dir]);
fid = fopen(fullfile(conf.result_dir, 'index.html'), 'wt');
fprintf(fid, ...
    '<HTML><HEAD><TITLE>Super-Resolution Summary</TITLE></HEAD><BODY>');

fprintf(fid, '<H1>Simulation results</H1>\n');

%conf.calc = @calc_PeakSNR_nob;
conf.calc = @calc_PeakSNR;
conf.units = 'dB';
calc_performance = @(f, g,sf) ...
    conf.calc(fullfile(conf.result_dir, f), fullfile(conf.result_dir, g),sf);
metric = sprintf('%s [%s] %s %s %s %s (Running time [s]) ', strrep(func2str(conf.calc), 'calc_', ''), conf.units,...
                 'SAM','ergas','UIQI','SSIM');
fprintf(fid, metric);
% Table header
fprintf(fid, '<TABLE border="1">\n');
fprintf(fid, '<TR>');
for i = 1:numel(conf.desc)
    fprintf(fid, '<TD>%s</TD>', conf.desc{i});
end
fprintf(fid, '</TR>\n');

image_write = @(image, filename) ...
    save(fullfile(conf.result_dir, filename),'image');

fprintf('Writing results to HTML summary...\n');
psnr = zeros(numel(conf.filenames),numel(conf.results{1}));
sam = zeros(numel(conf.filenames),numel(conf.results{1}));
ergas = zeros(numel(conf.filenames),numel(conf.results{1}));
uiqi = zeros(numel(conf.filenames),numel(conf.results{1}));
ssim = zeros(numel(conf.filenames),numel(conf.results{1}));
for i = 1:numel(conf.filenames)        
    fprintf('%d/%d:', i, numel(conf.filenames));
    X = load(conf.results{i}{1});
    X = X.img;
    for j = 1:numel(conf.results{i})
        [dummy, f] = split_path(conf.results{i}{j});
        load(conf.results{i}{j});
        image_write(img, f);
        conf.results{i}{j} = f;
    end

    
    [p, f, x] = fileparts(conf.filenames{i});
    f0 = [f '[0-Thumb].mat'];
    fprintf(fid, '<TR><TD><A HREF=%s><IMG SRC=%s TITLE="%s"></A></TD>\n', ...
        esc(conf.results{i}{1}), f0, f);
%     X = X(:, :, 1, 1)./255; % Take the original and scale it down to a 64x64 thumbnail
%     image_write(imresize(X, round(64*size(X)/size(X, 2))), f0);
    image_write(imresize(X, 1/8,'bicubic'), f0);
    fprintf('\t[%s]', f);    
    for j = 2:numel(conf.results{i})
        [psnr_HR,rmse_HR, ergas_HR, sam_HR, uiqi_HR,ssim_HR,DD_HR,CC_HR] = calc_performance(conf.results{i}{1}, conf.results{i}{j},upscaling);
        psnr(i,j) = psnr_HR;
%         fprintf(fid, '<TD><A HREF=%s>%.2f</A>(%.2f)</TD>\n', ...
%             esc(conf.results{i}{j}), psnr_HR, conf.countedtime(j-1,i));
        fprintf(fid, '<TD><A HREF=%s>%.4f</A>|', ...
            esc(conf.results{i}{j}), psnr_HR);
        fprintf(' : %.1f dB', psnr_HR)
        sam(i,j) = sam_HR;
        fprintf(fid, '<A HREF=%s>%.4f</A>|', ...
            esc(conf.results{i}{j}), sam_HR);
        ergas(i,j) = ergas_HR;
        fprintf(fid, '<A HREF=%s>%.4f</A>|', ...
            esc(conf.results{i}{j}), ergas_HR);
        uiqi(i,j) = uiqi_HR;
        fprintf(fid, '<A HREF=%s>%.4f</A>|', ...
            esc(conf.results{i}{j}), uiqi_HR);
        ssim(i,j) = ssim_HR;
        fprintf(fid, '<A HREF=%s>%.4f</A>(%.2f)</TD>', ...
            esc(conf.results{i}{j}), ssim_HR, conf.countedtime(j-1,i));
    end
    fprintf(fid, '</TR>\n');
    fprintf('\n');
end
fprintf(fid, '<TR><TD>Average PSNR</TD>\n');
% mscores = mean(psnr);
mpsnr = mean(psnr,1);
msam = mean(sam,1);
mergas = mean(ergas,1);
muiqi = mean(uiqi,1);
mssim = mean(ssim,1);
fprintf('\tAverage: ');
for i = 2:length(mpsnr)
    fprintf(fid, '<TD>%.4f| %.4f| %.4f| %.4f| %.4f(%.2f)</TD>\n', mpsnr(i),msam(i),mergas(i),muiqi(i),mssim(i),mean(conf.countedtime(i-1,:)));
    fprintf(' : %.2f dB',mpsnr(i));    
end;
fprintf(fid, '</TR>\n');
fprintf('\n');
fprintf(fid, '</TABLE>\n');
if isfield(conf, 'etc')
    fprintf(fid, '<H2>%s</H2>\n', conf.etc);
else
    fprintf(fid, '<H1>Simulation parameters</H1>\n<TABLE border="1">\n');
    fprintf(fid, sprintf('<TR><TD>Scaling factor<TD>x%d</TR>\n', conf.scale));
    fprintf(fid, sprintf('<TR><TD>High-res. patch size<TD>%d x %d</TR>\n', ...
        conf.window(1) * conf.scale, conf.window(2) * conf.scale));
    fprintf(fid, sprintf('<TR><TD>Feature upsampling factor<TD>%d\n', ...
        conf.upsample_factor));
    fprintf(fid, sprintf('<TR><TD>Feature dim. (original)<TD>%d</TR>\n', ...
        size(conf.V_pca, 1)));
    fprintf(fid, sprintf('<TR><TD>Feature dim. (reduced)<TD>%d</TR>\n', ...
        size(conf.V_pca, 2)));
    fprintf(fid, sprintf('<TR><TD>Dictionary size<TD>%d</TR>\n', ...
        conf.ksvd_conf.dictsize));
    fprintf(fid, sprintf('<TR><TD>Dictionary maximal sparsity<TD>%d</TR>\n', ...
        conf.ksvd_conf.Tdata));
    fprintf(fid, sprintf('<TR><TD>Dictionary iterations<TD>%d</TR>\n', ...
        conf.ksvd_conf.iternum));
    fprintf(fid, sprintf('<TR><TD>Duration<TD>%.1f seconds</TR>\n', ...
        conf.duration));
    fprintf(fid, sprintf('<TR><TD># of images<TD>%d</TR>\n', ...
        numel(conf.filenames)));
    fprintf(fid, sprintf('<TR><TD>Interpolation Kernel<TD>%s</TR>\n', ...
        conf.interpolate_kernel));
    fprintf(fid, '</TABLE>\n');
end

fprintf(fid, '%s\n', datestr(now));
fprintf(fid, '</BODY></HTML>\n');
fclose(fid);
fprintf('\n');

function s = esc(s)
s = strrep(s, ' ', '%20');
