# choose to make default (by default), handout, or notes to create slides for each jobname.tex
# respectively called jobname.pdf, jobname_handout.pdf or jobname_notes.pdf

# input files : all tex, figures, bib, etc. Some may not exist
TEX=$(wildcard *.tex)
BIB=$(wildcard *.bib)
# All directories for figures
FIG_DIRS=beamertheme Figures

# From there, work out which tex documents are 'root' (not included by others), and svg figures have latex text (called from includesvg)
SRC=$(shell grep -l '^\\begin{document}' $(TEX))
SVG_FIGS=$(foreach fd, $(FIG_DIRS), $(wildcard $(fd)/*.svg))
SVG_TEX_INCLUDES=$(addsuffix .svg, $(shell grep -ho '\\includesvg\(\[[\\0-9\.a-z+-]*\]\)\?{[^}]*}' $(TEX) | sed 's/^.*{//;s/}.*//' | sort | uniq))
SVG_TEX_FIGS=$(patsubst %.svg, %.pdf_tex, $(filter $(addprefix %, $(SVG_TEX_INCLUDES)), $(SVG_FIGS)))
SVG_PLAIN_FIGS=$(patsubst %.svg, %.pdf, $(filter-out $(addprefix %, $(SVG_TEX_INCLUDES)), $(SVG_FIGS)))

# commands
LATEX=pdflatex -file-line-error -shell-escape -interaction=nonstopmode
BIBTEX=bibtex -terse
MKINDEX=makeindex -s /usr/share/texmf/makeindex/nomencl/nomencl.ist

# parsing / processing of log file
RERUN='(There were undefined (references|citations)|Rerun to get (cross-references|the bars|outlines) right)'
UNDEFINED='((Reference|Citation).*undefined)|(Label.*multiply defined)'
MISSINGBBL='No file .*\.bbl\.'

.PHONY: default clean allclean handout notes
.SECONDARY: $(SVG_PLAIN_FIGS) $(SVG_TEX_FIGS)

# difference between handout and presentation compilations
define IN_FILE
$(if $(HANDOUT), "\\PassOptionsToClass{handout}{beamer}\\input{$(strip $1)}", $(if $(NOTES), "\\PassOptionsToClass{notes}{beamer}\\input{$(strip $1)}", "$(strip $1)" ) )
endef

# pseudo-targets
default:$(patsubst %.tex, %.pdf, $(SRC))
	@echo done building $^

handout:HANDOUT=1
handout:$(patsubst %.tex, %_handout.pdf, $(SRC))
	@echo done building $^

notes:NOTES=1
notes:$(patsubst %.tex, %_notes.pdf, $(SRC))
	@echo done building $^

#actual targets
%.pdf:%.svg
	@inkscape -C -z --file=$< --export-pdf=$@

%.pdf_tex:%.svg
	@inkscape -C -z --file=$< --export-pdf=$(@:.pdf_tex=.pdf) --export-latex
	# fixes https://bugs.launchpad.net/ubuntu/+bug/1417470 in inkscape 0.91 since we don't use pages inside Figures
	# works for up to 9 includegraphics in .pdf_tex
	@sed -ir "/\\includegraphics\[width=[^,]+,page=[`pdfinfo $(@:.pdf_tex=.pdf) | sed -n 's/Pages: */1 + /p' | bc`-9]\]/d" $@

%_handout.pdf %_notes.pdf %.pdf: %.tex $(SVG_TEX_FIGS) $(SVG_PLAIN_FIGS) $(BIB)
	$(LATEX) -jobname=$(basename $@) $(call IN_FILE, $*.tex)
	@#$(MKINDEX) $(basename $@).nlo -o $(basename $@).nls
	@if [[ -f "$(basename $@).bbl" ]] || grep -q $(MISSINGBBL) $(basename $@).log; then $(BIBTEX) $(basename $@).aux ; \
		$(LATEX) -jobname=$(basename $@) $(call IN_FILE, $*.tex); fi
	@if egrep -q $(RERUN) $(basename $@).log ; then $(LATEX) -jobname=$(basename $@) $(call IN_FILE, $*.tex) ; fi
	@if egrep -q $(RERUN) $(basename $@).log ; then $(LATEX) -jobname=$(basename $@) $(call IN_FILE, $*.tex) ; fi
	@echo "Undefined references : "
	@egrep -i $(UNDEFINED) $(basename $@).log || echo "None"


# cleanup
EXTS=.log .bbl .blg .nls .nlo .lof .lot .ilg .out .toc .aux .snm .vrb .nav .bcf -blx.bib .run.xml
allclean:EXTS+=pdf pdf_tex

allclean:clean
	@rm -rfv $(SVG_TEX_FIGS) $(patsubst %.pdf_tex, %.pdf, $(SVG_TEX_FIGS)) $(SVG_PLAIN_FIGS)
clean:
	@rm -rfv $(foreach ext, $(EXTS), $(wildcard *$(ext)))

