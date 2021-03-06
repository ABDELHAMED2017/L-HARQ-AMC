clear;
%clc;
%clf;

load AMC_policy_16QAM_Perfect_Decoding_continuous_R_dop_0.05rho_0.95156.mat
% load AMC_policy_16QAM_Perfect_Decoding_continuous_R_dop_0.1rho_0.8167.mat

load MI_16QAM.mat
MI_16QAM=[0 MI_16QAM(1:end-1)' 4];
th=[0 10.^((SNR(1:end-1))'./10) 1e10];
Qam_th=@(R) interp1(MI_16QAM,th,R);
Qam_r=@(gamma) interp1(th,MI_16QAM,gamma);

SNRdB=[-5:30];
K=4;
N_realization=1e5;

for ind_snr=1:1:length(SNRdB)
    
    snr=10.^(SNRdB(ind_snr)./10);
    sigma=sqrt((1-rho).*snr./2);
    snr_m=[1e-20 snr_range(ind_snr,:) 1e100];
    policy_m=[policy(ind_snr,1) policy(ind_snr,:) policy(ind_snr,end)];
    
    eR = normrnd(0,sigma,1,N_realization);
    eI = normrnd(0,sigma,1,N_realization);
    heR = normrnd(0,sqrt(snr./2),1,N_realization);
    heI = normrnd(0,sqrt(snr./2),1,N_realization);
    gammae=heR.^2+ heI.^2;
    gamma=(sqrt(rho).*heR-eR).^2+(sqrt(rho).*heI-eI).^2;
    
    delta_set=logspace(0,log10(snr_range(ind_snr,end-1)),50);
    
    for ind_delta=1:length(delta_set)
        [ind_snr ind_delta]
        snr_mm=snr_m./delta_set(ind_delta);
        counter=0;
        reward=0;
        while counter<N_realization-3
            counter=counter+1;
            rate_round_1=interp1(snr_mm,policy_m,gammae(counter));
            wep_round_1=Qam_r(gamma(counter))<rate_round_1;
            ack_round_1=1-wep_round_1;
            if ack_round_1==1
                reward=reward+rate_round_1;
            else
                BK_rate_round_1 = rate_round_1-Qam_r(gamma(counter));
                rate_round_2=interp1(snr_mm,policy_m,gammae(counter+1));
                if BK_rate_round_1<=rate_round_2
                    wep_round_2=Qam_r(gamma(counter+1))<rate_round_2;
                    ack_round_2=1-wep_round_2;
                    if ack_round_2==1
                        reward=reward+(rate_round_2+rate_round_1-BK_rate_round_1);
                        counter=counter+1;
                    else
                        BK_rate_round_2 = rate_round_2-Qam_r(gamma(counter+1));
                        rate_round_3=interp1(snr_mm,policy_m,gammae(counter+2));
                        if BK_rate_round_2<=rate_round_3
                            wep_round_3=Qam_r(gamma(counter+2))<rate_round_3;
                            ack_round_3=1-wep_round_3;
                            if ack_round_3==1
                                reward=reward+(rate_round_3+rate_round_2-BK_rate_round_2+rate_round_1-BK_rate_round_1);
                                counter=counter+2;
                            else
                                BK_rate_round_3 = rate_round_3-Qam_r(gamma(counter+2));
                                rate_round_4=interp1(snr_mm,policy_m,gammae(counter+3));
                                if BK_rate_round_3<=rate_round_4
                                    wep_round_4=Qam_r(gamma(counter+3))<rate_round_4;
                                    ack_round_4=1-wep_round_4;
                                    reward=reward+(rate_round_4+rate_round_3-BK_rate_round_3+rate_round_2-BK_rate_round_2...
                                        +rate_round_1-BK_rate_round_1).*ack_round_4;
                                    counter=counter+3;
                                else
                                    counter=counter+2;
                                end
                            end
                        else
                            counter=counter+1;
                        end
                    end
                end
            end
        end
        throughput_lharq_delta(ind_delta,ind_snr)=reward/counter;
    end
    [throughput_lharq(ind_snr),jj]=max(throughput_lharq_delta(:,ind_snr));
    optimal_delta(ind_snr)=delta_set(jj);
end


save LHARQ_translated_AMC_policy_16QAM_K_4_Perfect_Decoding_continuous_R_dop_0.05_rho_0.95_V_LHARQ_Correct.mat  dop rho SNRdB ...
    throughput_lharq_delta throughput_lharq  snr_range policy optimal_delta

% save LHARQ_translated_AMC_policy_16QAM_K_4_Perfect_Decoding_continuous_R_dop_0.05_rho_0.95_V_LHARQ_Correct.mat  dop rho SNRdB ...
%    throughput_lharq_delta throughput_lharq  snr_range policy optimal_delta

