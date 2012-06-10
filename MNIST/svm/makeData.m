close all;
clc; 
clear;


prefix001 = 'C:\Users\yichangshih\Desktop\sanskrit\data\train_svm\1\';
prefix011 = 'C:\Users\yichangshih\Desktop\sanskrit\data\train_svm\11\';
prefix012 = 'C:\Users\yichangshih\Desktop\sanskrit\data\train_svm\12\';
prefix013 = 'C:\Users\yichangshih\Desktop\sanskrit\data\train_svm\13\';
prefix027 = 'C:\Users\yichangshih\Desktop\sanskrit\data\train_svm\27\';
prefix033 = 'C:\Users\yichangshih\Desktop\sanskrit\data\train_svm\33\';
prefix052 = 'C:\Users\yichangshih\Desktop\sanskrit\data\train_svm\52\';

imList001 = dir([prefix001 '*.png']);
imList011 = dir([prefix011 '*.png']);
imList012 = dir([prefix012 '*.png']);
imList013 = dir([prefix013 '*.png']);
imList027 = dir([prefix027 '*.png']);
imList033 = dir([prefix033 '*.png']);
imList052 = dir([prefix052 '*.png']);

k = [0.8 1];
isData = [1 1 1 1 1 1 1 ];

%% Training data
for d = 1 : 2 
img = {};
label = {};
data = struct( 'img', {} , 'label',{});
head = 0 ; 
nlabel = 1; 

if( isData(1)) % 001
for i = 1 : round( length(imList001)*k(d))
    img{i + head} = imread([prefix001 imList001(i).name]);
    label{i + head } = nlabel;
end;
head = head + round( length(imList001)*k(d));
nlabel = nlabel + 1 ;
end

if( isData(2)) % 011
for i = 1 :  round( length(imList011)*k(d))
    img{i + head} = imread([prefix011 imList011(i).name]);
    label{i + head } = nlabel;
end;
head = head + round( length(imList011)*k(d));
nlabel = nlabel + 1 ;
end

if( isData(3)) % 012
for i = 1 :  round( length(imList012)*k(d))
    img{i + head} = imread([prefix012 imList012(i).name]);
    label{i + head } = nlabel;
end;
head = head + round( length(imList012)*k(d));
nlabel = nlabel + 1 ;
end

if( isData(4)) % 013
for i = 1 :  round( length(imList013)*k(d))
    img{i + head} = imread([prefix013 imList013(i).name]);
    label{i + head } = nlabel;
end;
head = head + round( length(imList013)*k(d));
nlabel = nlabel + 1 ;
end

if( isData(5)) % 027
for i = 1 :  round( length(imList027)*k(d))
    img{i + head} = imread([prefix027 imList027(i).name]);
    label{i + head } = nlabel;
end;
head = head + round( length(imList027)*k(d));
nlabel = nlabel + 1 ;
end

if( isData(6)) % 033
for i = 1 :  round( length(imList033)*k(d))
    img{i + head} = imread([prefix033 imList033(i).name]);
    label{i + head } = nlabel;
end;
head = head + round( length(imList033)*k(d));
nlabel = nlabel + 1 ;
end

if( isData(7)) % 052
for i = 1 :  round( length(imList052)*k(d))
    img{i + head} = imread([prefix052 imList052(i).name]);
    label{i + head } = nlabel;
end;
head = head + round( length(imList052)*k(d));
nlabel = nlabel + 1 ;
end

data = struct( 'img', img , 'label',label);
if(d==1)
    save trainingData data
elseif(d==2)
        save testingData data
end

end