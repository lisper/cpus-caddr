
 
 
 




window new WaveWindow  -name  "Waves for BMG Example Design"
waveform  using  "Waves for BMG Example Design"


      waveform add -signals /ise_16kx49ram_tb/status
      waveform add -signals /ise_16kx49ram_tb/ise_16kx49ram_synth_inst/bmg_port/CLKA
      waveform add -signals /ise_16kx49ram_tb/ise_16kx49ram_synth_inst/bmg_port/ADDRA
      waveform add -signals /ise_16kx49ram_tb/ise_16kx49ram_synth_inst/bmg_port/DINA
      waveform add -signals /ise_16kx49ram_tb/ise_16kx49ram_synth_inst/bmg_port/WEA
      waveform add -signals /ise_16kx49ram_tb/ise_16kx49ram_synth_inst/bmg_port/ENA
      waveform add -signals /ise_16kx49ram_tb/ise_16kx49ram_synth_inst/bmg_port/DOUTA
console submit -using simulator -wait no "run"
