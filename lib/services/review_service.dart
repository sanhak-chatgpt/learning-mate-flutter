import 'package:get/get.dart';
import 'package:in_app_review/in_app_review.dart';

class ReviewService extends GetxService {
  var requestedReviewAlready = false;

  Future requestReview() async {
    if (requestedReviewAlready) return;
    requestedReviewAlready = true;

    if (await InAppReview.instance.isAvailable()) {
      InAppReview.instance.requestReview();
    }
  }

  void openStoreListing() async {
    InAppReview.instance.openStoreListing(appStoreId: '6449399069');
  }
}
