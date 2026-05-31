import 'package:flutter/material.dart';

class StepIndicator extends StatelessWidget {
  final int totalSteps;
  final int currentStep;

  const StepIndicator({
    required this.totalSteps,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps * 2 - 1, (i) {
        if (i.isOdd) {
          return Expanded(
            child: Container(
              height: 2,
              // color: isPassed ? Colors.white : Colors.white.withOpacity(0.35),
              color: Colors.white,
            ),
          );
        }

        final stepIndex = i ~/ 2;
        final isPassed = stepIndex < currentStep;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8, // desfoque
                  spreadRadius: 2, // expansão
                  offset: const Offset(0, 8), // (horizontal, vertical)
                ),
              ],
              shape: BoxShape.circle,
              color: isPassed ? const Color(0xFF143B74) : Colors.white,
              // color: Colors.white,
              // border: Border.all(color: Colors.white, width: 2),
              border: isPassed
                  ? Border.all(color: const Color(0xFF143B74))
                  : Border.all(color: Colors.white)),
          alignment: Alignment.center,
          child: isPassed
              ? const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 18,
                )
              : Text(
                  '${stepIndex + 1}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
        );
      }),
    );
  }
}
