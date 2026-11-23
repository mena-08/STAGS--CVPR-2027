# supplementary.tex reads the main paper's labels from main.aux (xr-hyper \externaldocument{main}).
# Build main.tex first whenever supplementary.tex needs main.aux (Overleaf and local latexmk).
add_cus_dep('tex', 'aux', 0, 'makeexternaldocument');
sub makeexternaldocument {
    if (!($root_filename eq $_[0])) {
        system("latexmk -cd -pdf -interaction=nonstopmode \"$_[0]\"");
    }
}
