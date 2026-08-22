$for(publications)$
### $if(publications.path)$[$publications.title$]($publications.path$)$else$$publications.title$$endif$

*$publications.subtitle$*$if(publications.date)$, $publications.date$$endif$

$for(publications.authors)$$publications.authors$$sep$, $endfor$

$if(publications.doi)$$publications.doi$

$endif$$endfor$
