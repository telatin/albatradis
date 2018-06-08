'''Driver class'''
from tradistron.PrepareInputFiles import PrepareInputFiles
import logging
import os
import sys
import time
from tradistron.TradisGeneInsertSites import TradisGeneInsertSites
from tradistron.PrepareInputFiles import PrepareInputFiles
from tradistron.TradisEssentiality import TradisEssentiality

class PlotEssentiality:
	def __init__(self, plotfile_obj,gene_insert_sites_filename, tradis_essentiality_filename, type):
		self.plotfile_obj = plotfile_obj
		self.gene_insert_sites_filename = gene_insert_sites_filename
		self.tradis_essentiality_filename = tradis_essentiality_filename
		self.type = type
		
class PlotAllEssentiality:
	def __init__(self, forward, reverse, combined):
		self.forward = forward
		self.reverse = reverse
		self.combined = combined

class TradisTron:
	def __init__(self, options):
		self.logger            = logging.getLogger(__name__)
		self.plotfiles         = options.plotfiles
		self.minimum_threshold = options.minimum_threshold
		self.window_size       = options.window_size
		self.window_interval   = options.window_interval
		self.verbose           = options.verbose
		
		if self.verbose:
			self.logger.setLevel(logging.DEBUG)
		else:
			self.logger.setLevel(logging.ERROR)
		
	def run(self):
		plotfile_objects = self.prepare_input_files()
		self.run_essentiality(plotfile_objects)
		return self
		
	def prepare_input_files(self):
		plotfile_objects = {}
		for plotfile in self.plotfiles:
			p = PrepareInputFiles(plotfile, self.minimum_threshold, self.window_size, self.window_interval )
			p.create_all_files()
			plotfile_objects[plotfile] = p
			
			print("Forward plot:\t" + p.forward_plot_filename)
			print("reverse plot:\t" + p.reverse_plot_filename)
			print("combined plot:\t" + p.combined_plot_filename)
			print("Embl:\t" + p.embl_filename)
		return plotfile_objects
	
	def essentiality(self, plotfile_objects, plotfile, filetype):
		g = TradisGeneInsertSites(plotfile_objects[plotfile].embl_filename, getattr(plotfile_objects[plotfile], filetype + "_plot_filename"))
		g.run()
		e = TradisEssentiality(g.output_filename)
		e.run()
		pe = PlotEssentiality(plotfile, g.output_filename, e.output_filename, filetype)
		
		print("essentiality:\t" + filetype + "\t" + e.output_filename)
		return pe
		
	def run_essentiality(self,plotfile_objects):
		essentiality_files = {}
		for plotfile in plotfile_objects:
			
			f = self.essentiality(plotfile_objects, plotfile, 'forward')
			r = self.essentiality(plotfile_objects, plotfile, 'reverse')
			c = self.essentiality(plotfile_objects, plotfile, 'combined')
			
			essentiality_files[plotfile] = PlotAllEssentiality(f,r,c)

		return essentiality_files
		