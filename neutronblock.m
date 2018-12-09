% Input:
% h - Dicke der Wand
% la - Faktor der Exponentialverteilung
% q - Wahrscheinlickeit der Absorption
% n - Anzahl Versuche
% k - Wie viele Schritte auf einmal gemacht werden
% plt - Wird ein Plot angeziegt?
%     0 - nein
%     1 - 2D Plot
%     2 - 3D Plot
%----------
% Output:
% y = [(-),(0),(+)]^T - Anzahl der F�lle
%----------
function y = neutronblock(h,la,q,n,k,plt)
    %Standarm��ig kein Anfang
    if nargin < 6
        plt = 0;
    end
    %Standarm��ig 50 Wiederholungen
    if nargin < 5
        k = 5;
    end
    
    %Anzahl von +,0,-
    y = zeros(3,1);
    
    %Initialisieren
    start = 1;
    s = zeros(3,n);
    
    if plt
        colors = repmat(get(gca,'colororder'),[ceil(n/7),1]);
        colors = colors(1:n,:)
        title("Neutronenbeschuss")
        xlabel("x")
        ylabel("y")
        hold on
    end
    
    while(n > 0)
    
        %Generieren von Zufallsvektoren mit Richtung vereilt nach ballvert()
        %(Ausnahme: am Anfang [1,0,0]^T) und L�nge verteilt nach expvert()
        %    dim 1 - Vektor
        %    dim 2 - n Verusche
        %    dim 3 - k Wiederholungen
        w = repmat(reshape(expvert(la,n*k),[1,n,k]),[3,1,1]);
        r = reshape(ballvert(n*k),[3,n,k]);
        if start
            r(1,:,1) = 1;
            r([2,3],:,1) = 0;
        end
        z = w.*r;
        
        %Alle Zwischenwerte durch aufsummieren (ohne Startvektoren)
        z = cat(3,s,z);
        z = cumsum(z,3);
        
        %lf/rf/af Wurde ein Vektor gefunden wurde an das jw. Ereignis stattfand?
        %   l - linker Wandaustritt
        %   r - rechter Wandaustritt
        %   a - Absorption
        %l/r/a    passende Indices
        [lf,l] = max( z(1,:,2:end) <= 0, [], 3);
        [rf,r] = max( z(1,:,2:end) >= h, [], 3);
        [af,a] = max(rand(k,n) <= q, [], 1);
        a = a + 1;             %Im ersten Schritt keine Absorption
        
        %Welcher Fall tratt zuert ein und wann?
        l(lf == 0) = k+1;
        r(rf == 0) = k+1;
        a(af == 0) = k+1;
        t = min(min(l,r),a);
        mask = a == t;         %Stellen an denen Absorbiert wurde
        l(mask) = k+1;         %sind wichtiger als andere
        r(mask) = k+1;
        
        %Plotten
        if plt > 0
            %Nan falls schon fertig
            Y = repmat(reshape(1:k+1,[1,1,k+1]),[3,n,1]);
            T = repmat(t,[3,1,k+1]);
            z(Y>T) = nan;
            %ploten
            if plt == 1
                for i = 1:n
                    plot(reshape(z(1,i,:),[k+1,1,1]), reshape(z(2,i,:),[k+1,1,1]),'Color',colors(i,:))
                end
            end
            if plt == 2
                for i = 1:n
                    plot3(reshape(z(1,i,:),[k+1,1,1]), reshape(z(2,i,:),[k+1,1,1]), reshape(z(3,i,:),[k+1,1,1]), 'Color',colors(i,:))
                end
            end
            colors = colors(repmat((t == k+1)',[1,3]));
            colors = reshape(colors,length(colors)/3,3);
            %plot([1,n+1],[-a,-a]);
            %plot([1,n+1],[b,b]);
            %axis([1,max(t)*(21/20),-a-(a+b)/20,b+(a+b)/20]);
        end
        
        %Anzahlen
        y(1) = y(1) + sum(l(l == t) ~= k+1);
        y(2) = y(2) + sum(a(mask) ~= k+1);
        y(3) = y(3) + sum(r(r == t) ~= k+1);
        
        %neuer Startvektor wo Simulation noch nicht fertig ist
        s = z(:,:,end);
        s = s(repmat(t == k+1,[3,1]));
        s = reshape(s,3,length(s)/3);
        n = size(s,2)
        
        start = 0;
    end
end