<?php

namespace Dbu\Bundle\CoreBundle\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\Controller;
use Symfony\Component\HttpFoundation\Request;
use Dbu\Bundle\CoreBundle\Entity\Comment;

class CommentsController extends Controller
{
    const FILE = '/tmp/comments';

    public function commentsAction()
    {
        $response = $this->render('DbuCoreBundle:Comments:comments.html.twig', array(
            'comments' => $this->getComments(),
        ));
        $response->setMaxAge(3600); // will be manually invalidated
        $response->setPublic();
        return $response;
    }

    public function formAction()
    {
        $response = $this->render('DbuCoreBundle:Comments:form.html.twig', array(
            'form' => $this->getForm()->createView(),
        ));
        // depends on the session to inline the user name
        // it this is the only bit that prevents caching, you could use javascript
        // to pre-fill the name in the frontend and cache the form
        $response->setVary('Cookie', false);
        $response->setMaxAge(0);
        $response->setPrivate();
        return $response;
    }

    public function postAction(Request $request)
    {
        $form = $this->getForm();
        $form->bindRequest($request);

        if ($form->isValid()) {
            $comments = $this->getComments();
            $comments[] = $form->getData();
            if (! file_put_contents(self::FILE, serialize($comments))) {
                die('failed to write the data file');
            }

            // invalidate the varnish cache of the comments sub block so the new comment is shown
            $varnish = $this->container->get('liip_cache_control.varnish');
            $kernel = $this->container->get('http_kernel');
            $varnish->invalidatePath($kernel->generateInternalUri('DbuCoreBundle:Comments:comments'));

            return $this->redirect($this->generateUrl('home'));
        }
    }

    private function getForm()
    {
        $comment = new Comment();
        $security = $this->get('security.context');
        if ($security->isGranted('IS_AUTHENTICATED_FULLY')) {
            $comment->author = $security->getToken()->getUser()->getUsername();
        }

        $form = $this->createFormBuilder($comment)
            ->add('author')
            ->add('text')
            ->getForm();

        return $form;
    }

    private function getComments()
    {
        if (! file_exists(self::FILE)) {
            return array();
        }
        return unserialize(file_get_contents(self::FILE));
    }
}
