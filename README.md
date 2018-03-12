# HOBA backend

HRTFs On demand for Binaural Audio (HOBA) framework provides personalized HRTF selection based on anthropometric data, i.e., pinnae shape. This repository contains the backend part of the framework.

Pinna contours are first traced manually to extract an array of distances from user's ear canal entrance. The service then computes a frequency domain similarity measure between the extracted ray array and precaptured non-individual HRTF sets, and returns a best match HRTF set. The HRTF set is transferred in the proposed WAVH format.
