function [ pixel_proposals ] = search ( mask, window )
%{
Jonatan Poveda
Martí Cobos
Juan Francesc Serracant
Ferran Pérez
Master in Computer Vision
Computer Vision Center, Barcelona
---------------------------
Project M1/Week3
---------------------------
This function does a linear and naive search over a mask and return the pixels
which context has some properties defined for `decisionTree`.
input:  - mask: nxm binary mask
        - window: nxm (even size) binary matrix that will be applied to determine
          which area analyze from the mask. Must be smaller than the mask.
output: - list of pixels susceptible to be from an object.
---------------------------
%}
  debug = false;
  is_a_signal = false;
  center = ((size(window,1)-1)/2);

  % Find pixel candidates
  candidates = findCandidates(mask);

  % Init
  i = 1;
  pixel_proposals(i,:) = [0 0];

  regions_scanned = 0;
  % Check each candidate and save positive ones
  for candidate = 1:size(candidates,1)
    if debug
      sprintf('Checking candidate %d', candidate)
    end
    c = candidates(candidate,:);
    range = [c(1)-center, c(1)+center, c(2)-center, c(2)+center];
    try
      region = mask(range(1):range(2), range(3):range(4)).*window;
      regions_scanned = regions_scanned + 1;
      if debug
        sprintf('Checking region %d', regions_scanned);
      end
      signalClass = checkRegion(region, 0);
      if strcmp(signalClass,'X') == 0   % It seems to be an object
        pixel_proposals(i) = c;
        i = i + 1;
      end
    catch
      % Skip if a window cannot be centered on this pixel
    end
    % imshow(region,[]); title(signalClass);
    % pause(1);
  end
  sprintf('Number of regions scanned: %d/%d', ...
          regions_scanned,size(candidates, 1))
end
