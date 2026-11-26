
//input ports
add mapped point clk clk -type PI PI
add mapped point rst_n rst_n -type PI PI
add mapped point start_i start_i -type PI PI
add mapped point pixel_i[7] pixel_i[7] -type PI PI
add mapped point pixel_i[6] pixel_i[6] -type PI PI
add mapped point pixel_i[5] pixel_i[5] -type PI PI
add mapped point pixel_i[4] pixel_i[4] -type PI PI
add mapped point pixel_i[3] pixel_i[3] -type PI PI
add mapped point pixel_i[2] pixel_i[2] -type PI PI
add mapped point pixel_i[1] pixel_i[1] -type PI PI
add mapped point pixel_i[0] pixel_i[0] -type PI PI

//output ports
add mapped point load_o load_o -type PO PO
add mapped point pixel_idx_o[9] pixel_idx_o[9] -type PO PO
add mapped point pixel_idx_o[8] pixel_idx_o[8] -type PO PO
add mapped point pixel_idx_o[7] pixel_idx_o[7] -type PO PO
add mapped point pixel_idx_o[6] pixel_idx_o[6] -type PO PO
add mapped point pixel_idx_o[5] pixel_idx_o[5] -type PO PO
add mapped point pixel_idx_o[4] pixel_idx_o[4] -type PO PO
add mapped point pixel_idx_o[3] pixel_idx_o[3] -type PO PO
add mapped point pixel_idx_o[2] pixel_idx_o[2] -type PO PO
add mapped point pixel_idx_o[1] pixel_idx_o[1] -type PO PO
add mapped point pixel_idx_o[0] pixel_idx_o[0] -type PO PO
add mapped point busy_o busy_o -type PO PO
add mapped point done_o done_o -type PO PO
add mapped point prediction_o[3] prediction_o[3] -type PO PO
add mapped point prediction_o[2] prediction_o[2] -type PO PO
add mapped point prediction_o[1] prediction_o[1] -type PO PO
add mapped point prediction_o[0] prediction_o[0] -type PO PO

//inout ports




//Sequential Pins
add mapped point u_fc/in_rd_addr[4]/q u_fc_in_rd_addr_reg[4]/Q -type DFF DFF
add mapped point u_fc/in_rd_addr[9]/q u_fc_in_rd_addr_reg[9]/Q -type DFF DFF
add mapped point u_fc/in_rd_addr[8]/q u_fc_in_rd_addr_reg[8]/Q -type DFF DFF
add mapped point u_fc/in_rd_addr[3]/q u_fc_in_rd_addr_reg[3]/Q -type DFF DFF
add mapped point u_fc/r_oc[2]/q u_fc_r_oc_reg[2]/Q -type DFF DFF
add mapped point u_fc/in_rd_addr[6]/q u_fc_in_rd_addr_reg[6]/Q -type DFF DFF
add mapped point u_conv1/r_ox[3]/q u_conv1_r_ox_reg[3]/Q -type DFF DFF
add mapped point u_fc/r_oc[3]/q u_fc_r_oc_reg[3]/Q -type DFF DFF
add mapped point u_fc/in_rd_addr[2]/q u_fc_in_rd_addr_reg[2]/Q -type DFF DFF
add mapped point u_fc/in_rd_addr[1]/q u_fc_in_rd_addr_reg[1]/Q -type DFF DFF
add mapped point u_fc/in_rd_addr[5]/q u_fc_in_rd_addr_reg[5]/Q -type DFF DFF
add mapped point u_fc/in_rd_addr[0]/q u_fc_in_rd_addr_reg[0]/Q -type DFF DFF
add mapped point u_fc/in_rd_addr[7]/q u_fc_in_rd_addr_reg[7]/Q -type DFF DFF
add mapped point u_conv1/r_ox[2]/q u_conv1_r_ox_reg[2]/Q -type DFF DFF
add mapped point state[1]/q state_reg[1]/Q -type DFF DFF
add mapped point u_fc/r_oc[1]/q u_fc_r_oc_reg[1]/Q -type DFF DFF
add mapped point u_conv1/r_oy[3]/q u_conv1_r_oy_reg[3]/Q -type DFF DFF
add mapped point u_fc/r_oc[0]/q u_fc_r_oc_reg[0]/Q -type DFF DFF
add mapped point u_conv2/r_ox[2]/q u_conv2_r_ox_reg[2]/Q -type DFF DFF
add mapped point u_conv2/r_oy[2]/q u_conv2_r_oy_reg[2]/Q -type DFF DFF
add mapped point u_fc/state[0]/q u_fc_state_reg[0]/Q -type DFF DFF
add mapped point state[0]/q state_reg[0]/Q -type DFF DFF
add mapped point u_conv1/r_kx[0]/q u_conv1_r_kx_reg[0]/Q -type DFF DFF
add mapped point u_conv2/r_kx[1]/q u_conv2_r_kx_reg[1]/Q -type DFF DFF
add mapped point u_conv1/r_kx[1]/q u_conv1_r_kx_reg[1]/Q -type DFF DFF
add mapped point u_conv2/r_oy[3]/q u_conv2_r_oy_reg[3]/Q -type DFF DFF
add mapped point u_conv2/r_ox[3]/q u_conv2_r_ox_reg[3]/Q -type DFF DFF
add mapped point u_conv2/r_ic[2]/q u_conv2_r_ic_reg[2]/Q -type DFF DFF
add mapped point u_conv2/r_ic[0]/q u_conv2_r_ic_reg[0]/Q -type DFF DFF
add mapped point u_conv2/r_ic[3]/q u_conv2_r_ic_reg[3]/Q -type DFF DFF
add mapped point u_fc/state[1]/q u_fc_state_reg[1]/Q -type DFF DFF
add mapped point u_conv1/r_oc[2]/q u_conv1_r_oc_reg[2]/Q -type DFF DFF
add mapped point u_conv1/r_ox[1]/q u_conv1_r_ox_reg[1]/Q -type DFF DFF
add mapped point u_conv1/r_oc[1]/q u_conv1_r_oc_reg[1]/Q -type DFF DFF
add mapped point u_conv2/r_ic[1]/q u_conv2_r_ic_reg[1]/Q -type DFF DFF
add mapped point u_conv1/r_ox[0]/q u_conv1_r_ox_reg[0]/Q -type DFF DFF
add mapped point u_conv1/r_oy[2]/q u_conv1_r_oy_reg[2]/Q -type DFF DFF
add mapped point u_conv2/r_ky[1]/q u_conv2_r_ky_reg[1]/Q -type DFF DFF
add mapped point u_conv2/r_oc[4]/q u_conv2_r_oc_reg[4]/Q -type DFF DFF
add mapped point u_conv2/r_kx[0]/q u_conv2_r_kx_reg[0]/Q -type DFF DFF
add mapped point u_conv2/r_ky[0]/q u_conv2_r_ky_reg[0]/Q -type DFF DFF
add mapped point u_conv1/r_ky[1]/q u_conv1_r_ky_reg[1]/Q -type DFF DFF
add mapped point u_conv1/r_oc[3]/q u_conv1_r_oc_reg[3]/Q -type DFF DFF
add mapped point u_conv2/r_oc[1]/q u_conv2_r_oc_reg[1]/Q -type DFF DFF
add mapped point u_conv1/state[1]/q u_conv1_state_reg[1]/Q -type DFF DFF
add mapped point u_conv1/state[0]/q u_conv1_state_reg[0]/Q -type DFF DFF
add mapped point u_conv1/r_ox[4]/q u_conv1_r_ox_reg[4]/Q -type DFF DFF
add mapped point u_conv2/r_oc[0]/q u_conv2_r_oc_reg[0]/Q -type DFF DFF
add mapped point u_conv2/r_oc[2]/q u_conv2_r_oc_reg[2]/Q -type DFF DFF
add mapped point u_conv2/r_oc[3]/q u_conv2_r_oc_reg[3]/Q -type DFF DFF
add mapped point u_conv2/r_ox[0]/q u_conv2_r_ox_reg[0]/Q -type DFF DFF
add mapped point u_conv1/r_oc[0]/q u_conv1_r_oc_reg[0]/Q -type DFF DFF
add mapped point u_conv2/r_ox[1]/q u_conv2_r_ox_reg[1]/Q -type DFF DFF
add mapped point u_conv2/r_oy[1]/q u_conv2_r_oy_reg[1]/Q -type DFF DFF
add mapped point u_conv1/r_ky[0]/q u_conv1_r_ky_reg[0]/Q -type DFF DFF
add mapped point u_conv1/r_oy[1]/q u_conv1_r_oy_reg[1]/Q -type DFF DFF
add mapped point u_conv2/state[0]/q u_conv2_state_reg[0]/Q -type DFF DFF
add mapped point u_conv1/r_oy[0]/q u_conv1_r_oy_reg[0]/Q -type DFF DFF
add mapped point pix_cnt[9]/q pix_cnt_reg[9]/Q -type DFF DFF
add mapped point u_conv2/r_oy[0]/q u_conv2_r_oy_reg[0]/Q -type DFF DFF
add mapped point u_conv2/state[2]/q u_conv2_state_reg[2]/Q -type DFF DFF
add mapped point u_conv1/r_oy[4]/q u_conv1_r_oy_reg[4]/Q -type DFF DFF
add mapped point u_conv2/state[1]/q u_conv2_state_reg[1]/Q -type DFF DFF
add mapped point pix_cnt[8]/q pix_cnt_reg[8]/Q -type DFF DFF
add mapped point pool2_ch[4]/q pool2_ch_reg[4]/Q -type DFF DFF
add mapped point pool2_ch[3]/q pool2_ch_reg[3]/Q -type DFF DFF
add mapped point pix_cnt[7]/q pix_cnt_reg[7]/Q -type DFF DFF
add mapped point pool2_ch[1]/q pool2_ch_reg[1]/Q -type DFF DFF
add mapped point pool2_ch[2]/q pool2_ch_reg[2]/Q -type DFF DFF
add mapped point pool2_ch[0]/q pool2_ch_reg[0]/Q -type DFF DFF
add mapped point pix_cnt[6]/q pix_cnt_reg[6]/Q -type DFF DFF
add mapped point pool1_ch[3]/q pool1_ch_reg[3]/Q -type DFF DFF
add mapped point pool1_ch[2]/q pool1_ch_reg[2]/Q -type DFF DFF
add mapped point pool1_ch[1]/q pool1_ch_reg[1]/Q -type DFF DFF
add mapped point pool1_ch[0]/q pool1_ch_reg[0]/Q -type DFF DFF
add mapped point pix_cnt[5]/q pix_cnt_reg[5]/Q -type DFF DFF
add mapped point state[3]/q state_reg[3]/Q -type DFF DFF
add mapped point pix_cnt[2]/q pix_cnt_reg[2]/Q -type DFF DFF
add mapped point pix_cnt[4]/q pix_cnt_reg[4]/Q -type DFF DFF
add mapped point pool1_y[0]/q pool1_y_reg[0]/Q -type DFF DFF
add mapped point pool2_y[2]/q pool2_y_reg[2]/Q -type DFF DFF
add mapped point pool2_y[1]/q pool2_y_reg[1]/Q -type DFF DFF
add mapped point pix_cnt[3]/q pix_cnt_reg[3]/Q -type DFF DFF
add mapped point pix_cnt[1]/q pix_cnt_reg[1]/Q -type DFF DFF
add mapped point pix_cnt[0]/q pix_cnt_reg[0]/Q -type DFF DFF
add mapped point pool2_y[0]/q pool2_y_reg[0]/Q -type DFF DFF
add mapped point pool1_x[3]/q pool1_x_reg[3]/Q -type DFF DFF
add mapped point pool1_x[2]/q pool1_x_reg[2]/Q -type DFF DFF
add mapped point pool1_y[1]/q pool1_y_reg[1]/Q -type DFF DFF
add mapped point load_o/q load_o_reg/Q -type DFF DFF
add mapped point pool1_y[3]/q pool1_y_reg[3]/Q -type DFF DFF
add mapped point state[2]/q state_reg[2]/Q -type DFF DFF
add mapped point pool1_y[2]/q pool1_y_reg[2]/Q -type DFF DFF
add mapped point pool1_x[1]/q pool1_x_reg[1]/Q -type DFF DFF
add mapped point pool1_x[0]/q pool1_x_reg[0]/Q -type DFF DFF
add mapped point pool2_x[1]/q pool2_x_reg[1]/Q -type DFF DFF
add mapped point pool2_x[2]/q pool2_x_reg[2]/Q -type DFF DFF
add mapped point pool2_x[0]/q pool2_x_reg[0]/Q -type DFF DFF
add mapped point fc_start_r/q fc_start_r_reg/Q -type DFF DFF
add mapped point c1_start_r/q c1_start_r_reg/Q -type DFF DFF
add mapped point c2_start_r/q c2_start_r_reg/Q -type DFF DFF
add mapped point busy_o/q busy_o_reg/Q -type DFF DFF
add mapped point u_conv1/state[2]/q u_conv1_state_reg[2]/Q -type DFF DFF
add mapped point state[4]/q state_reg[4]/Q -type DFF DFF
add mapped point done_o/q done_o_reg/Q -type DFF DFF
add mapped point u_fc/state[2]/q u_fc_state_reg[2]/Q -type DFF DFF
add mapped point u_conv1/done_o/q u_conv1_done_o_reg/Q -type DFF DFF
add mapped point u_fc/done_o/q u_fc_done_o_reg/Q -type DFF DFF
add mapped point u_conv2/done_o/q u_conv2_done_o_reg/Q -type DFF DFF



//Black Boxes



//Empty Modules as Blackboxes
