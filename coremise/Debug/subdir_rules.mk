################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Each subdirectory must supply rules for building sources it contributes
%.obj: ../%.asm $(GEN_OPTS) | $(GEN_FILES) $(GEN_MISC_FILES)
	@echo 'Building file: "$<"'
	@echo 'Invoking: MSP430 Compiler'
	"/Applications/ti/ccs1240/ccs/tools/compiler/ti-cgt-msp430_21.6.1.LTS/bin/cl430" -vmspx --code_model=small --data_model=small --use_hw_mpy=F5 --include_path="/Applications/ti/ccs1240/ccs/ccs_base/msp430/include" --include_path="/Users/panchi/Documents/university/1st-semester-2023-2024/INEL4206 - Microprocessors/ccs_files/workspace_v12/coremise" --include_path="/Applications/ti/ccs1240/ccs/tools/compiler/ti-cgt-msp430_21.6.1.LTS/include" --advice:power=all --advice:hw_config=all --define=__MSP430FR6989__ --define=_MPU_ENABLE -g --printf_support=minimal --diag_warning=225 --diag_wrap=off --display_error_number --silicon_errata=CPU21 --silicon_errata=CPU22 --silicon_errata=CPU40 --preproc_with_compile --preproc_dependency="$(basename $(<F)).d_raw" $(GEN_OPTS__FLAG) "$<"
	@echo 'Finished building: "$<"'
	@echo ' '


