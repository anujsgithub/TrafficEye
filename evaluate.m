load 'models/AcfPureDetector.mat'

%pModify=struct('cascThr',-1,'cascCal',.01);
pModify = struct('nOctUp',1.1);
detector1=acfModify(detector,pModify);

load 'models/AcfPureDetector.mat'

cellArray =cell(1,2);
cellArrayBB =cell(1,2);

%pModify=struct('cascThr',-1,'cascCal',.01);
pModify = struct('nOctUp',1.1);
detector2 = acfModify(detector,pModify);

%detector = {detector1,detector2};

%Read Video Files
fileNamesList = {
             '17754840'; '17754873'; '18704651'; '18704652'; '18704717';
             '18704748'; '18704752'; '18704756'; '18704793'; '18704836'
             '18704861'; '18704869'; '18704899'; '18704960'; '18704968';
             '18705087'; '18705249'; '18705316'; '18705335'; '18705343';
             '18705449'; '18705451'; '18705456'; '18705458'; '18705459';
             '18705460'; '18705463'; '18705466'; '18705467'; '18705468';
             '18705470'; '18705472'; '18705473'; '18705478'; 'keepright'; 
             'keeprightStop'; 'stopsigns'};
%            '18705449'; '18705451'; '18705456'; '18705458'; '18705459';
%            '18705460'; '18705463'; '18705466'; '18705467'};

for y=1:37

cellArrayBB={0 0};
%Write video file
videoFileName=char(fileNamesList(y));
vidObj = VideoReader(strcat('/Users/koray/Desktop/trafficSignVideos/testVideos/',videoFileName,'.mp4'));

vidHeight = vidObj.Height;
vidWidth = vidObj.Width;

s = struct('cdata',zeros(vidHeight,vidWidth,3,'uint8'),'colormap',[]);
vw = VideoWriter(strcat('/Users/koray/Desktop/trafficSignVideos/Results/',videoFileName,'out.mp4'),'MPEG-4');
open(vw);

Files=dir(strcat('/Users/koray/Desktop/trafficSignVideos/Annotations/',videoFileName));
%Ground Truth Array
gArray = zeros(length(Files)-2,5);
for k=4:length(Files)
   fileNames=Files(k).name;
   cArray= strsplit(fileNames(1:end-3),'_');
   if y < 35
        gArray(k-2,1) = str2num(char(cArray(4)));
        gArray(k-2,2) = str2num(char(cArray(6)));
        gArray(k-2,3) = str2num(char(cArray(7)));
        gArray(k-2,4) = str2num(char(cArray(8)));
        gArray(k-2,5) = str2num(char(cArray(9)));
   else
        gArray(k-2,1) = str2num(char(cArray(2)));
        gArray(k-2,2) = str2num(char(cArray(4)));
        gArray(k-2,3) = str2num(char(cArray(5)));
        gArray(k-2,4) = str2num(char(cArray(6)));
        gArray(k-2,5) = str2num(char(cArray(7)));
   end
end

k = 1;
fileID = fopen(strcat(videoFileName,'.txt'),'w');

tic
while hasFrame(vidObj)
    s(k).cdata = readFrame(vidObj);
    I=s(k).cdata;
    tic
    bbs=acfDetect(I,detector1);
    toc
    bbs2 = bbs(find(bbs(:,5)>32)',:);
    
    

    
    %bbs3 =bbs2(find(bbs2(:,1)+bbs2(:,3)<size(I,2)-5)',:);
    %bbs4 =bbs3(find(bbs3(:,2)+bbs3(:,4)<size(I,1)-5)',:);
    %bbs5 =bbs4(find(bbs4(:,1)>0)',:);
    %bbs6 =bbs5(find(bbs5(:,2)>0)',:);
    %J=bbApply('embed', I, floor(bbs6));
    %writeVideo(vw,J);
    
    %Write detection scores into a file
    detBBs = numel(bbs2(:,1));
    for j=1:detBBs        
        fprintf(fileID,'%4d, %3d, %3d, %3d, %3d, %5.3f\n',[k round(bbs2(j,1)) round(bbs2(j,2)) round(bbs2(j,3)) round(bbs2(j,4)) bbs2(j,5)]);
    end
    markCheck = zeros(detBBs,1);
    
    if find(gArray(:,1)==k)
        imshow(I)
        index=find(gArray(:,1)==k);
        rect1=[gArray(index,2) gArray(index,3) gArray(index,4) gArray(index,5)];
                for t=1:detBBs
                    rect2=bbs2(t,1:4);
                    v1 =bbs2(t,1:2);
                    %intersection = rectint(rect1,rect2);
                    score = bboxOverlapRatio(rect1,rect2);
                    if max(score) >= 0.5
                        cellArray(end+1,:)={1 bbs2(t,5)};
                        cellArrayBB(end+1,:)={bbs2(t,1) bbs2(t,2)};
                        disp('here');
                        RGB = insertShape(I, 'Rectangle', [bbs2(t,1) bbs2(t,2) bbs2(t,3) bbs2(t,4)]);
                        imshow(RGB);
                        markCheck(t)=1;
                    else
                        %arrayIn = find(gArray(:,1) ~= k);
                        matrix2 = cell2mat(cellArrayBB);
                        if size(cellArrayBB,1)>1
                            for j=2:numel(matrix2(:,1))
                                v2=[matrix2(j,1) matrix2(j,2)];
                                if norm(v1-v2) < 45
                                    markCheck(t)=2;
                                    disp('here3');
                                end
                            end
                        end
                    end                   
                end
    end
    for t=1:detBBs
        if markCheck(t) ==0
           %if bbs2(t,3) >= 30
                cellArray(end+1,:)={0 bbs2(t,5)};
           %end
        end
    end
    k = k+1;
end
toc
close(vw);
fclose(fileID);
end
matrix1 = cell2mat(cellArray);
[prec, tpr, fpr, thresh] = prec_rec(matrix1(:,2)', matrix1(:,1)', 'plotROC',1,'holdFigure',1);